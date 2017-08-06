module prometheus.collector;

import prometheus.common;

public class Collector {
	string _namespace;
	string _subsystem;
	string _name;
	string _fullname;
	string _help;

	string[] _labelNames;

	public abstract class Child {}

	protected Child[string[]] children;
	protected Child noLabelsChild;

	//public abstract Collector collect();
	public abstract string getTextExposition();
	public abstract string getType();

	public string getName() {
		return _name;
	}

	this() {}

	this(string name, string help, string[] labelNames) {
		checkMetricName(name);
		checkHelp(help);
		checkLabelNames(labelNames);
		this._name = name;
		this._help = help;
		this._labelNames = labelNames;
	}

	static string getLabelsTextExposition(in string[] labelNames, in string[] labelValues) {
		import prometheus.exposition.text;
		import std.array;
		import std.format;
		if (!labelNames.length)
			return "";

		string[] labelText;
		foreach (i, labelName; labelNames) {
			labelText ~= LABEL.format(labelName, labelValues[i]);
		}

		return "{" ~ labelText.join(SEPARATOR) ~ "}";
	}
}
