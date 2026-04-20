package com.example.demo.concurrent;

import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public final class NamedThreadPoolFactory {
  private NamedThreadPoolFactory() {
  }

  public static ThreadPoolExecutor create(String prefix) {
    AtomicInteger counter = new AtomicInteger(1);
    ThreadFactory threadFactory =
        runnable -> {
          Thread thread = new Thread(runnable);
          thread.setName(prefix + "-" + counter.getAndIncrement());
          return thread;
        };
    return new ThreadPoolExecutor(
        2, 4, 60L, TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>(128), threadFactory);
  }
}
