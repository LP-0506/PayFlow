// Test fixture only. This is not any PayFlow business service.
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;
public final class RuntimeFixture {
    public static void main(String[] args) throws Exception {
        var server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/", exchange -> {
            var body = "{\"status\":\"UP\",\"fixture\":true}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, body.length);
            try (var out = exchange.getResponseBody()) { out.write(body); }
        });
        server.setExecutor(Executors.newFixedThreadPool(2));
        Runtime.getRuntime().addShutdownHook(new Thread(() -> server.stop(2)));
        server.start();
    }
}
