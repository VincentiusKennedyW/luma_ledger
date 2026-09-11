package app.lumaledger.luma_ledger

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var receipts: ReceiptBridge
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        receipts = ReceiptBridge(this, engine.dartExecutor.binaryMessenger)
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) receipts.receive(intent)
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receipts.receive(intent)
    }
    @Deprecated("Activity result bridge for the native document picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::receipts.isInitialized) receipts.picked(requestCode, resultCode, data)
    }
    override fun onDestroy() {
        if (::receipts.isInitialized) receipts.close()
        super.onDestroy()
    }
}
