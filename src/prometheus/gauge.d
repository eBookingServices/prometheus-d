module prometheus.gauge;

import prometheus.collector;
import prometheus.common;



public class Gauge : Collector {
	private double counterValue;

	this() {
		counterValue = 0;
	}
	this(string name, string help, string[] labels) {
		counterValue = 0;
		super(name, help, labels);
	}
	mixin BasicCollectorClassConstructor!Gauge;

	public double get() {
		return counterValue;
	}

	public void setToCurrentTime() {
		import std.datetime;
		return set(Clock.currTime().toUnixTime());
	}

	public void inc() {
		return inc(1);
	}

	public void inc(double amt) {
		synchronized {
			counterValue += amt;
		}
	}

	public void dec() {
		return inc(-1);
	}

	public void dec(double amt) {
		return inc(-amt);
	}

	public void set(double amt) {
		synchronized {
			counterValue = amt;
		}
	}

	override public string[] namesToRegister() {
		return [];
	}
}


unittest {
	import std.stdio;
	import std.format;
	auto gauge = new Gauge().name("test").help("Help");
	assert(gauge._name == "test", "Name differs");
	assert(gauge._help == "Help", "help differs");

	gauge.inc();
	assert(gauge.get() == 1, "Not equal to 1");
	gauge.inc(3);
	assert(gauge.get() == 4, "Not equal to 4");
	gauge.dec(2);
	assert(gauge.get() == 2, "Not equal to 2");

	gauge.dec();
	assert(gauge.get() == 1, "Not equal to 1");

	import std.datetime;
	gauge.setToCurrentTime();
	assert(gauge.get() == Clock.currTime().toUnixTime(), "Not equal to current unix timestamp");
}
