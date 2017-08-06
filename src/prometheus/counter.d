module prometheus.counter;

import prometheus.collector;
import prometheus.common;



public class Counter : Collector {
	this() {
		noLabelsChild = new Counter.Child();
	}
	this(string name, string help, string[] labels) {
		if (!labels.length)
			noLabelsChild = new Counter.Child();
		super(name, help, labels);
	}
	mixin BasicCollectorClassConstructor!Counter;
	mixin getSimpleTextExpositionTemplate!Counter;

	override public string getType() {
		return "counter";
	}

	public double get() {
		auto child = cast(Counter.Child)noLabelsChild;
		return child.get();
	}

	public void inc() {
		auto child = cast(Counter.Child)(noLabelsChild);
		return child.inc();
	}

	public void inc(double amt) {
		auto child = cast(Counter.Child)(noLabelsChild);
		return child.inc(amt);
	}

	class Child : Collector.Child {
		private double value;

		this() {
			value = 0;
		}

		public double get() {
			return value;
		}

		public void inc() {
			return inc(1);
		}

		public void inc(double amt) {
			if (amt < 0)
				throw new IllegalArgumentException("Amount to increment must be non-negative.");

			synchronized {
				value += amt;
			}
		}
	}
}


unittest {
	import std.stdio;
	import std.format;
	auto counter = new Counter().name("test").help("Help");
	assert(counter._name == "test", "Name differs");
	assert(counter._help == "Help", "help differs");

	counter.inc();
	assert(counter.get() == 1, "Not equal to 1");
	counter.inc(3);
	assert(counter.get() == 4, "Not equal to 4");

	auto counter2 = new Counter().name("test").help("Help")
		.labelNames(["some_test_label", "some_other_test_label"]);

	counter2.labels(["some_value", "some_other_value"]).inc();
	counter2.labels(["some_value", "some_other_value"]).inc();

	assert(counter2.labels(["some_value", "some_other_value"]).get() == 2,
		"Get with labels failed");

	assert(counter.getTextExposition() == "# HELP test Help
# TYPE test counter
test 4", "Text exposition doesn't look good dude");

	assert(counter2.getTextExposition() == "# HELP test Help
# TYPE test counter
test{some_test_label=\"some_value\",some_other_test_label=\"some_other_value\"} 2",
	"Text exposition with labels doesn't look good dude");

	//writeln("%s".format(counter.getTextExposition()));
}
