module prometheus.collectorRegistry;

import prometheus.common;
import prometheus.collector;

shared static this() {
	CollectorRegistry.defaultRegistry = new CollectorRegistry(true);
}

public class CollectorRegistry {
	public static CollectorRegistry defaultRegistry;

	private Collector[string] nameToCollector;
	private bool autoDescribe;

	public this() {
		this(false);
	}

	public this(bool autoDescribe) {
		this.autoDescribe = autoDescribe;
	}

	public void register(Collector m) {
		auto names = m.namesToRegister();
		synchronized {
			foreach (name; names) {
				if (m.name in nameToCollector)
					throw new IllegalArgumentException("Collector already registered that provides name: " ~ m.name);

				nameToCollector[m.name] = m;
			}
		}
	}

	public void unregister(Collector m) {
		auto names = m.namesToRegister();
		synchronized {
			foreach (name; names)
				nameToCollector.remove(m.name);
		}
	}

	public void clear() {
		synchronized {
			nameToCollector = null;
		}
	}
}
