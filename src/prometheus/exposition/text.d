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

	auto counter2 = new Counter().name("ziCounter2").help("Help").labelNames(["http_code", "some_other_shit"]);
	CollectorRegistry.defaultRegistry.register(counter2);

	writeln("Gonna test with empty %s".format(CollectorRegistry.defaultRegistry.generateExpositionText()));
	assert(CollectorRegistry.defaultRegistry.generateExpositionText() == q{# HELP ziCounter Help
# TYPE ziCounter counter
ziCounter 0
# HELP ziCounter2 Help
# TYPE ziCounter2 counter
ziCounter2 0

}, "Not bery nice text exposition when empty");

	counter.inc();
	counter.inc();
	counter.inc();

	counter2.labels(["1", "2"]).inc();
	counter2.labels(["1", "2"]).inc();
	counter2.labels(["1", "2"]).inc();
	counter2.labels(["1", "3"]).inc();

	auto gauge = new Gauge().name("ziGauge").help("Help");
	CollectorRegistry.defaultRegistry.register(gauge);

	auto gauge2 = new Gauge().name("ziGauge2").help("Help").labelNames(["ramala", "jamala"]);
	CollectorRegistry.defaultRegistry.register(gauge2);

	gauge.inc();
	gauge.inc();

	gauge2.labels(["super", "awesome"]).inc();
	gauge2.labels(["super", "awesome"]).inc();
	gauge2.labels(["super", "awesome"]).inc();

	auto histogram = new Histogram().name("ziHist").help("Help").buckets(Histogram.DEFAULT_BUCKETS);
	CollectorRegistry.defaultRegistry.register(histogram);

	assert(CollectorRegistry.defaultRegistry.generateExpositionText() == q{# HELP ziGauge Help
# TYPE ziGauge gauge
ziGauge 2
# HELP ziCounter Help
# TYPE ziCounter counter
ziCounter 3
# HELP ziCounter2 Help
# TYPE ziCounter2 counter
ziCounter2{http_code="1",some_other_shit="3"} 1
ziCounter2{http_code="1",some_other_shit="2"} 3
# HELP ziHist Help
# TYPE ziHist histogram
ziHist_bucket{le="0.005"} 0
ziHist_bucket{le="0.01"} 0
ziHist_bucket{le="0.025"} 0
ziHist_bucket{le="0.05"} 0
ziHist_bucket{le="0.075"} 0
ziHist_bucket{le="0.1"} 0
ziHist_bucket{le="0.25"} 0
ziHist_bucket{le="0.5"} 0
ziHist_bucket{le="0.75"} 0
ziHist_bucket{le="1"} 0
ziHist_bucket{le="2.5"} 0
ziHist_bucket{le="5"} 0
ziHist_bucket{le="7.5"} 0
ziHist_bucket{le="10"} 0
ziHist_bucket{le="+Inf"} 0
ziHist_sum 0
ziHist_count 0
# HELP ziGauge2 Help
# TYPE ziGauge2 gauge
ziGauge2{ramala="super",jamala="awesome"} 3

}, "Not bery nice text exposition");

	histogram.observe(3);

	//writeln("%s".format(CollectorRegistry.defaultRegistry.generateExpositionText()));
	assert(CollectorRegistry.defaultRegistry.generateExpositionText() == q{# HELP ziGauge Help
# TYPE ziGauge gauge
ziGauge 2
# HELP ziCounter Help
# TYPE ziCounter counter
ziCounter 3
# HELP ziCounter2 Help
# TYPE ziCounter2 counter
ziCounter2{http_code="1",some_other_shit="3"} 1
ziCounter2{http_code="1",some_other_shit="2"} 3
# HELP ziHist Help
# TYPE ziHist histogram
ziHist_bucket{le="0.005"} 0
ziHist_bucket{le="0.01"} 0
ziHist_bucket{le="0.025"} 0
ziHist_bucket{le="0.05"} 0
ziHist_bucket{le="0.075"} 0
ziHist_bucket{le="0.1"} 0
ziHist_bucket{le="0.25"} 0
ziHist_bucket{le="0.5"} 0
ziHist_bucket{le="0.75"} 0
ziHist_bucket{le="1"} 0
ziHist_bucket{le="2.5"} 0
ziHist_bucket{le="5"} 1
ziHist_bucket{le="7.5"} 1
ziHist_bucket{le="10"} 1
ziHist_bucket{le="+Inf"} 1
ziHist_sum 3
ziHist_count 1
# HELP ziGauge2 Help
# TYPE ziGauge2 gauge
ziGauge2{ramala="super",jamala="awesome"} 3

}, "Not bery nice text exposition");
}
