public class StateDemo {
  public void run() {
    try {
      int a = 1 / 0;
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}
