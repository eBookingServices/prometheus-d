module prometheus.counter;

import prometheus.collector;
import prometheus.common;



public class Counter : Collector {
	private double value;

	this() {
		value = 0;
	}
	this(string name, string help, string[string] labels) {
		value = 0;
		super(name, help, labels);
	}
	mixin BasicCollectorClassConstructor!Counter;
	mixin getSimpleTextExpositionTemplate;

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

	override public string getType() {
		return "counter";
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

	assert(counter.getTextExposition() == "# HELP test Help
# TYPE test counter
test 4", "Text exposition doesn't look good dude");

	//writeln("%s".format(counter.getTextExposition()));
}
