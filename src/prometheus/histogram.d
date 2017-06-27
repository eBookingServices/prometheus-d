module prometheus.histogram;

import prometheus.collector;
import prometheus.common;



public class Histogram : Collector {
	enum DEFAULT_BUCKETS = [.005, .01, .025, .05, .075, .1, .25, .5, .75, 1, 2.5, 5, 7.5, 10];
	private double[] _upperBounds;

	private double _sum;
	private ulong[] _bucketCounters;

	private void initializeBucketCounters() {
		_bucketCounters.reserve(_upperBounds.length);
		for(uint i; i < _upperBounds.length; ++i)
			_bucketCounters ~= 0;
	}

	this() {
		_sum = 0;
		_upperBounds = DEFAULT_BUCKETS;
		initializeBucketCounters();
	}
	this(string name, string help, string[] labels) {
		_sum = 0;
		_upperBounds = DEFAULT_BUCKETS;
		initializeBucketCounters();
		super(name, help, labels);
	}
	mixin BasicCollectorClassConstructor!Histogram;

	public Histogram buckets(double[] buckets) {
		if (_sum > 0)
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
			ulong[] _bucketCounters;
		}
		return Value(_sum, _bucketCounters);
	}

	public void observe(double amt) {
		synchronized {
			for (int i = 0; i < _upperBounds.length; ++i) {
				// The last bucket is +Inf, so we always increment.
				if (amt <= _upperBounds[i]) {
					++_bucketCounters[i];
					break;
				}
			}
			_sum += amt;
		}
	}

	override public string[] namesToRegister() {
		return [];
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
		assert(value._bucketCounters[0] == 0, "Bucket 0 is good");
		assert(value._bucketCounters[3] == 1, "Bucket 3 is good");
	}

	histogram.observe(1.5);
	{
		auto value = histogram.get();
		assert(value._sum == 3, "Sum is good");
		assert(value._bucketCounters[0] == 0, "Bucket 0 is good");
		assert(value._bucketCounters[3] == 2, "Bucket 3 is good");
	}

	histogram.observe(0.9);
	{
		auto value = histogram.get();
		assert(value._sum == 3.9, "Sum is good");
		assert(value._bucketCounters[0] == 0, "Bucket 0 is good");
		assert(value._bucketCounters[2] == 1, "Bucket 2 is good");
		assert(value._bucketCounters[3] == 2, "Bucket 3 is good");
	}
}
