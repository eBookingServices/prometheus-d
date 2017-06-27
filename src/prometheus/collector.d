module prometheus.collector;

import prometheus.common;

public class Collector {
	public string name;
	public string help;
	public string[] labels;
	//public Sample[] samples;

	//public abstract Collector collect();
	public abstract string[] namesToRegister();

	this() {}

	this(string name, string help, string[] labels) {
		checkMetricName(name);
		checkHelp(help);
		checkLabelNames(labels);
		this.name = name;
		this.help = help;
		this.labels = labels;
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
