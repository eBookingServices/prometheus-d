module prometheus.histogram;

import prometheus.collector;
import prometheus.common;



public class Histogram : Collector {
	enum DEFAULT_BUCKETS = [.005, .01, .025, .05, .075, .1, .25, .5, .75, 1, 2.5, 5, 7.5, 10];
	private double[] _upperBounds;

	private double _sum;
	private ulong _count;
	private ulong[] _bucketCounters;

	private void initializeBucketCounters() {
		_bucketCounters.reserve(_upperBounds.length);
		for(uint i; i < _upperBounds.length; ++i)
			_bucketCounters ~= 0;
	}

	this() {
		_sum = 0;
		_count = 0;
		_upperBounds = DEFAULT_BUCKETS;
		initializeBucketCounters();
	}
	this(string name, string help, string[string] labels) {
		_sum = 0;
		_count = 0;
		_upperBounds = DEFAULT_BUCKETS;
		initializeBucketCounters();
		super(name, help, labels);
	}
	mixin BasicCollectorClassConstructor!Histogram;

	public Histogram buckets(double[] buckets) {
		if (_count > 0)
			throw new IllegalArgumentException("Cannot call this on an initialized histogram");

		import std.algorithm;
		if (!buckets.isSorted)
			throw new IllegalArgumentException("The buckets array needs to be sorted");

		_upperBounds = buckets;
		initializeBucketCounters();

		return this;
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

	override public string getType() {
		return "histogram";
	}

	override public string getTextExposition() {
		import prometheus.exposition.text;
		import std.format;
		import std.array;
		import std.conv;

		string[] text;
		text ~= HELP_LINE.format(_name, escape(_help));
		text ~= TYPE_LINE.format(_name, getType());

		enum BUCKET = "%s_bucket";
		foreach (i, value; _upperBounds) {
			auto ziLabels = _labels.dup;
			ziLabels["le"] = value.to!string;
			text ~= METRIC_LINE.format(BUCKET.format(_name), getLabelsTextExposition(ziLabels), _bucketCounters[i]);
		}

		{
			auto ziLabels = _labels.dup;
			ziLabels["le"] = "+Inf";
			text ~= METRIC_LINE.format(BUCKET.format(_name), getLabelsTextExposition(ziLabels), _count);
		}

		text ~= METRIC_LINE.format(_name ~ "_sum", getLabelsTextExposition(), _sum);
		text ~= METRIC_LINE.format(_name ~ "_count", getLabelsTextExposition(), _count);

		return text.join(DELIMITER);
	}
}


unittest {
	import std.stdio;
	import std.format;
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
}
