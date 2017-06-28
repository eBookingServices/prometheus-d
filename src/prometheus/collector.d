module prometheus.collector;

import prometheus.common;

public class Collector {
	string _namespace;
	string _subsystem;
	string _name;
	string _fullname;
	string _help;
	string[string] _labels;

	//public abstract Collector collect();
	public abstract string getTextExposition();
	public abstract string getType();

	public string getName() {
		return _name;
	}

	this() {}

	this(string name, string help, string[string] labels) {
		checkMetricName(name);
		checkHelp(help);
		checkLabelNames(labels);
		this._name = name;
		this._help = help;
		this._labels = labels;
	}

	string getLabelsTextExposition() {
		return getLabelsTextExposition(_labels);
	}

	static string getLabelsTextExposition(string[string] labels) {
		import prometheus.exposition.text;
		import std.array;
		import std.format;
		if (!labels.length)
			return "";

		string[] labelText;
		foreach (name, value; labels) {
			labelText ~= LABEL.format(name, value);
		}

		return "{" ~ labelText.join(SEPARATOR) ~ "}";
	}

	// public class Sample {
	// 	public string name;
	// 	public string[] labelNames;
	// 	public string[] labelValues;
	// 	public double value;
	//
	// 	this(string name, string[] labelNames, string[] labelValues, double value) {
	// 		checkLabelNames(labelNames);
	// 		if (labelNames.length != labelValues.length)
	// 			throw new IllegalArgumentException("labelNames and labelValues need to have the same length");
	// 		this.name = name;
	// 		this.labelNames = labelNames;
	// 		this.labelValues = labelValues;
	// 		this.value = value;
	// 	}
	// }
}
