module prometheus.exposition.text;

import prometheus.collectorRegistry;

private enum MEDIA_TYPE	= "text/plain";
private enum VERSION		= "0.0.4";
enum CONTENT_TYPE = MEDIA_TYPE ~ "; version=" ~ VERSION;

enum METRIC_LINE = "%s%s %s";
enum TYPE_LINE   = "# TYPE %s %s";
enum HELP_LINE   = "# HELP %s %s";

enum LABEL			= "%s=\"%s\"";
enum SEPARATOR	= ',';
enum DELIMITER	= "\n";

string escape(string ziText) {
	import std.regex;
	auto lineFeedRegex = ctRegex!(r"\n", "g");
	auto backslashRegex = ctRegex!(r"\\", "g");
	auto doubleQuoteRegex = ctRegex!(`"`, "g");
	return ziText.replaceAll(lineFeedRegex, "\\n")
					.replaceAll(backslashRegex, "\\\\")
					.replaceAll(doubleQuoteRegex, "\\\"");
}

string generateExpositionText() {
	return generateExpositionText(CollectorRegistry.defaultRegistry);
}

string generateExpositionText(CollectorRegistry registry) {
	import std.array;

	string[] expText;
	foreach(collector; registry.getAllCollectors()) {
		expText ~= collector.getTextExposition();
	}

	return expText.join(DELIMITER) ~ DELIMITER ~ DELIMITER;
}


unittest {
	import prometheus.counter;
	import prometheus.gauge;
	import prometheus.histogram;
	import std.stdio;
	import std.format;

	auto counter = new Counter().name("ziCounter").help("Help");
	CollectorRegistry.defaultRegistry.register(counter);

	counter.inc();

	auto gauge = new Gauge().name("ziGauge").help("Help");
	CollectorRegistry.defaultRegistry.register(gauge);

	gauge.inc();
	gauge.inc();

	auto histogram = new Histogram().name("ziHist").help("Help");
	CollectorRegistry.defaultRegistry.register(histogram);

	writeln("%s".format(CollectorRegistry.defaultRegistry.generateExpositionText()));
	assert(CollectorRegistry.defaultRegistry.generateExpositionText() == "# HELP ziGauge Help
# TYPE ziGauge gauge
ziGauge 2
# HELP ziCounter Help
# TYPE ziCounter counter
ziCounter 1
# HELP ziHist Help
# TYPE ziHist histogram
ziHist_bucket{le=\"0.005\"} 0
ziHist_bucket{le=\"0.01\"} 0
ziHist_bucket{le=\"0.025\"} 0
ziHist_bucket{le=\"0.05\"} 0
ziHist_bucket{le=\"0.075\"} 0
ziHist_bucket{le=\"0.1\"} 0
ziHist_bucket{le=\"0.25\"} 0
ziHist_bucket{le=\"0.5\"} 0
ziHist_bucket{le=\"0.75\"} 0
ziHist_bucket{le=\"1\"} 0
ziHist_bucket{le=\"2.5\"} 0
ziHist_bucket{le=\"5\"} 0
ziHist_bucket{le=\"7.5\"} 0
ziHist_bucket{le=\"10\"} 0
ziHist_bucket{le=\"+Inf\"} 0
ziHist_sum 0
ziHist_count 0

", "Not bery nice text exposition");

	histogram.observe(3);

	assert(CollectorRegistry.defaultRegistry.generateExpositionText() == "# HELP ziGauge Help
# TYPE ziGauge gauge
ziGauge 2
# HELP ziCounter Help
# TYPE ziCounter counter
ziCounter 1
# HELP ziHist Help
# TYPE ziHist histogram
ziHist_bucket{le=\"0.005\"} 0
ziHist_bucket{le=\"0.01\"} 0
ziHist_bucket{le=\"0.025\"} 0
ziHist_bucket{le=\"0.05\"} 0
ziHist_bucket{le=\"0.075\"} 0
ziHist_bucket{le=\"0.1\"} 0
ziHist_bucket{le=\"0.25\"} 0
ziHist_bucket{le=\"0.5\"} 0
ziHist_bucket{le=\"0.75\"} 0
ziHist_bucket{le=\"1\"} 0
ziHist_bucket{le=\"2.5\"} 0
ziHist_bucket{le=\"5\"} 1
ziHist_bucket{le=\"7.5\"} 1
ziHist_bucket{le=\"10\"} 1
ziHist_bucket{le=\"+Inf\"} 1
ziHist_sum 3
ziHist_count 1

", "Not bery nice text exposition");
}
