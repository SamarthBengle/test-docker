public class HelloWorld {
    public static void main(String[] args) {
        String javaVersion = System.getProperty("java.version");
        String javaVendor = System.getProperty("java.vendor");

        System.out.println("=================================");
        System.out.println("Hello from Java!");
        System.out.println("Java Version: " + javaVersion);
        System.out.println("Java Vendor: " + javaVendor);
        System.out.println("=================================");
    }
}