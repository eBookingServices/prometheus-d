module prometheus.gauge;

import prometheus.collector;
import prometheus.common;



public class Gauge : Collector {
	this() {
		noLabelsChild = new Gauge.Child();
	}
	this(string name, string help, string[] labels) {
		if (!labels.length)
			noLabelsChild = new Gauge.Child();
		super(name, help, labels);
	}
	mixin BasicCollectorClassConstructor!Gauge;
	mixin getSimpleTextExpositionTemplate!Gauge;

	public double get() {
		auto child = cast(Gauge.Child)(noLabelsChild);
		return child.get();
	}

	public void inc() {
		auto child = cast(Gauge.Child)(noLabelsChild);
		return child.inc();
	}

	public void inc(double amt) {
		auto child = cast(Gauge.Child)(noLabelsChild);
		return child.inc(amt);
	}

	public void setToCurrentTime() {
		auto child = cast(Gauge.Child)(noLabelsChild);
		return child.setToCurrentTime();
	}

	public void dec(double amt) {
		auto child = cast(Gauge.Child)(noLabelsChild);
		return child.dec(amt);
	}

	public void dec() {
		auto child = cast(Gauge.Child)(noLabelsChild);
		return child.dec();
	}

	public void set(double amt) {
		auto child = cast(Gauge.Child)(noLabelsChild);
		return child.set(amt);
	}

	class Child : Collector.Child {
		private double value;

		this() {
			value = 0;
		}

		public double get() {
			return value;
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
				value += amt;
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
				value = amt;
			}
		}
	}

	override public string getType() {
		return "gauge";
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

	gauge.set(4.5);

	assert(gauge.getTextExposition() == "# HELP test Help
# TYPE test gauge
test 4.5", "Text exposition doesn't look good dude");
}
