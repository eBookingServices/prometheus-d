module prometheus.counter;

import prometheus.collector;
import prometheus.common;



public class Counter : Collector {
	private double counterValue;

	this() {
		counterValue = 0;
	}
	this(string name, string help, string[] labels) {
		counterValue = 0;
		super(name, help, labels);
	}
	mixin BasicCollectorClassConstructor!Counter;


	public double get() {
		return counterValue;
	}

	public void inc() {
		return inc(1);
	}

	public void inc(double amt) {
		if (amt < 0)
			throw new IllegalArgumentException("Amount to increment must be non-negative.");

		synchronized {
			counterValue += amt;
		}
	}

	override public string[] namesToRegister() {
		return [];
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
}
