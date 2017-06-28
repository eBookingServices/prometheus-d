module prometheus.collectorRegistry;

import prometheus.common;
import prometheus.collector;

shared static this() {
	CollectorRegistry.defaultRegistry = new CollectorRegistry();
}

public class CollectorRegistry {
	public static CollectorRegistry defaultRegistry;

	private Collector[string] nameToCollector;
	//private bool autoDescribe;

	public this() {
		//this(false);
	}

	// public this(bool autoDescribe) {
	// 	this.autoDescribe = autoDescribe;
	// }

	public auto getAllCollectors() {
		return nameToCollector.values;
	}

	public void register(Collector m) {
		synchronized {
				if (m.getName() in nameToCollector)
					throw new IllegalArgumentException("Collector already registered that provides name: " ~ m.getName());

				nameToCollector[m.getName()] = m;
		}
	}

	public void unregister(Collector m) {
		synchronized {
			nameToCollector.remove(m.getName());
		}
	}

	public void clear() {
		synchronized {
			nameToCollector = null;
		}
	}
}
