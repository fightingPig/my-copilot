public class HighRiskExecutors {
  public void createPool() {
    java.util.concurrent.ExecutorService executorService =
        java.util.concurrent.Executors.newFixedThreadPool(4);
    System.out.println(executorService);
  }
}
