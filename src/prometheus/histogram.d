module prometheus.histogram;

import prometheus.collector;
import prometheus.common;



public class Histogram : Collector {
	this() {
		noLabelsChild = new Histogram.Child();
	}
	this(string name, string help, string[] labels) {
		noLabelsChild = new Histogram.Child();
		super(name, help, labels);
	}
	mixin BasicCollectorClassConstructor!Histogram;

	public auto buckets(double[] buckets) {
		if (_upperBounds.length)
			throw new IllegalArgumentException("Cannot call this on an initialized histogram");

		import std.algorithm;
		if (!buckets.isSorted)
			throw new IllegalArgumentException("The buckets array needs to be sorted");

		_upperBounds = buckets;
		auto child = cast(Histogram.Child)(noLabelsChild);
		child.initializeBucketCounters();

		return this;
	}

	public auto get() {
		auto child = cast(Histogram.Child)(noLabelsChild);
		return child.get();
	}

	public auto observe(double amt) {
		auto child = cast(Histogram.Child)(noLabelsChild);
		return child.observe(amt);
	}

	enum DEFAULT_BUCKETS = [.005, .01, .025, .05, .075, .1, .25, .5, .75, 1, 2.5, 5, 7.5, 10];
	private double[] _upperBounds;
	class Child : Collector.Child {
		private ulong[] _bucketCounters;
		private ulong _count;
		private double _sum;

		this() {
			_sum = 0;
			_count = 0;
			initializeBucketCounters();
		}

		private void initializeBucketCounters() {
			_bucketCounters.reserve(_upperBounds.length);
			for(uint i; i < _upperBounds.length; ++i)
				_bucketCounters ~= 0;
		}

		public auto get() {
			static struct Value {
				double _sum;
				ulong _count;
				ulong[] _bucketCounters;
			}
			return Value(_sum, _count, _bucketCounters);
		}

		public void observe(double amt) {
			synchronized {
				for (int i = 0; i < _upperBounds.length; ++i) {
					// The last bucket is +Inf, so we always increment.
					if (amt <= _upperBounds[i])
						++_bucketCounters[i];
				}
				++_count;
				_sum += amt;
			}
		}
	}

	override public string getType() {
		return "histogram";
	}

	override public string getTextExposition() {
		import prometheus.exposition.text;
		import std.format;
		import std.array;

		string[] text;
		text ~= HELP_LINE.format(_name, escape(_help));
		text ~= TYPE_LINE.format(_name, getType());

		if (!children.keys.length) {
			auto child = cast(Histogram.Child)(noLabelsChild);
			text ~= getChildRepresentation(child);

			text ~= METRIC_LINE.format(_name ~ "_sum", "", child._sum);
			text ~= METRIC_LINE.format(_name ~ "_count", "", child._count);
		}
		else {
			foreach (labelValues, ziChild; children) {
				auto child = cast(Histogram.Child)(ziChild);
				text ~= getChildRepresentation(child, labelValues);

				text ~= METRIC_LINE.format(_name ~ "_sum", labelValues, child._sum);
				text ~= METRIC_LINE.format(_name ~ "_count", labelValues, child._count);
			}
		}

		return text.join(DELIMITER);
	}

	private string[] getChildRepresentation(Histogram.Child child, in string[] ziLabelValues = []) {
		import prometheus.exposition.text;
		import std.conv;
		import std.format;

		// when the histogram has not observed anything yet, there will be no labelValues
		auto labelNamesToUse = ziLabelValues.length ? _labelNames : [];

		enum BUCKET = "%s_bucket";
		string[] text;
		foreach (i, value; this._upperBounds) {
			auto labelNames = labelNamesToUse.dup;
			labelNames ~= "le";
			auto labelValues = ziLabelValues.dup;
			labelValues ~= value.to!string;
			text ~= METRIC_LINE.format(BUCKET.format(_name), getLabelsTextExposition(labelNames, labelValues), child._bucketCounters[i]);
		}

		text ~= METRIC_LINE.format(BUCKET.format(_name), getLabelsTextExposition(labelNamesToUse.dup ~ "le", ziLabelValues.dup ~ "+Inf"), child._count);

		return text;
	}
}


unittest {
	import std.stdio;
	import std.format;

	writeln("First Histogram test");
	auto histogram = new Histogram().name("test").help("Help").buckets([0.01, 0.1, 1, 2]);
	assert(histogram._name == "test", "Name differs");
	assert(histogram._help == "Help", "help differs");

	histogram.observe(1.5f);
	{
		auto value = histogram.get();
		//writeln(format("%s", value));
		assert(value._sum == 1.5, "Sum is good");
		assert(value._count == 1, "Count is good");
		assert(value._bucketCounters[0] == 0, "Bucket 0 is good");
		assert(value._bucketCounters[1] == 0, "Bucket 1 is good");
		assert(value._bucketCounters[2] == 0, "Bucket 2 is good");
		assert(value._bucketCounters[3] == 1, "Bucket 3 is good");
	}

	histogram.observe(1.5);
	{
		auto value = histogram.get();
		assert(value._sum == 3, "Sum is good");
		assert(value._count == 2, "Count is good");
		assert(value._bucketCounters[0] == 0, "Bucket 0 is good");
		assert(value._bucketCounters[1] == 0, "Bucket 1 is good");
		assert(value._bucketCounters[2] == 0, "Bucket 2 is good");
		assert(value._bucketCounters[3] == 2, "Bucket 3 is good");
	}

	histogram.observe(0.9);
	{
		auto value = histogram.get();
		assert(value._sum == 3.9, "Sum is good");
		assert(value._count == 3, "Count is good");
		assert(value._bucketCounters[0] == 0, "Bucket 0 is good");
		assert(value._bucketCounters[1] == 0, "Bucket 1 is good");
		assert(value._bucketCounters[2] == 1, "Bucket 2 is good");
		assert(value._bucketCounters[3] == 3, "Bucket 3 is good");
	}

	histogram.observe(0.02);
	{
		auto value = histogram.get();
		assert(value._sum == 3.92, "Sum is good");
		assert(value._count == 4, "Count is good");
		assert(value._bucketCounters[0] == 0, "Bucket 0 is good");
		assert(value._bucketCounters[1] == 1, "Bucket 1 is good");
		assert(value._bucketCounters[2] == 2, "Bucket 2 is good");
		assert(value._bucketCounters[3] == 4, "Bucket 3 is good");
	}

	//writeln(histogram.getTextExposition());
	assert(histogram.getTextExposition() == "# HELP test Help
# TYPE test histogram
test_bucket{le=\"0.01\"} 0
test_bucket{le=\"0.1\"} 1
test_bucket{le=\"1\"} 2
test_bucket{le=\"2\"} 4
test_bucket{le=\"+Inf\"} 4
test_sum 3.92
test_count 4", "Histogram expsition is not bery nice");


	writeln("Second Histogram test");
	auto histogram2 = new Histogram().name("jamla").help("description").labelNames(["code"])
		.buckets([10, 20, 30]);
	assert(histogram2._name == "jamla", "Name differs");
	assert(histogram2._help == "description", "help differs");

	histogram2.labels(["ah"]).observe(15);
	histogram2.labels(["ah"]).observe(0.2f);
	{
		auto value = histogram2.labels(["ah"]).get();
		//writeln(format("%s", value));
		assert(value._sum == 15.2, "Sum is good");
		assert(value._count == 2, "Count is good");
		assert(value._bucketCounters[0] == 1, "Bucket 0 is good");
		assert(value._bucketCounters[1] == 2, "Bucket 1 is good");
		assert(value._bucketCounters[2] == 2, "Bucket 2 is good");
	}

	histogram2.labels(["some_other_value"]).observe(1.8f);

	{
		auto value = histogram2.labels(["some_other_value"]).get();
		//writeln(format("%s", value));
		assert(value._sum == 1.8, "Sum is good");
		assert(value._count == 1, "Count is good");
		assert(value._bucketCounters[0] == 1, "Bucket 0 is good");
		assert(value._bucketCounters[1] == 1, "Bucket 1 is good");
		assert(value._bucketCounters[2] == 1, "Bucket 2 is good");
	}

	//writeln(histogram2.getTextExposition());
	assert(histogram2.getTextExposition() == "# HELP jamla description
# TYPE jamla histogram
jamla_bucket{code=\"ah\",le=\"10\"} 1
jamla_bucket{code=\"ah\",le=\"20\"} 2
jamla_bucket{code=\"ah\",le=\"30\"} 2
jamla_bucket{code=\"ah\",le=\"+Inf\"} 2
jamla_sum[\"ah\"] 15.2
jamla_count[\"ah\"] 2
jamla_bucket{code=\"some_other_value\",le=\"10\"} 1
jamla_bucket{code=\"some_other_value\",le=\"20\"} 1
jamla_bucket{code=\"some_other_value\",le=\"30\"} 1
jamla_bucket{code=\"some_other_value\",le=\"+Inf\"} 1
jamla_sum[\"some_other_value\"] 1.8
jamla_count[\"some_other_value\"] 1", "Histogram expsition is not bery nice");
}
