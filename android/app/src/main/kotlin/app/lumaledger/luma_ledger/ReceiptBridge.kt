package app.lumaledger.luma_ledger

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.io.InputStream
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors

/** Only explicitly shared/picked images are read; no notification or storage permission. */
class ReceiptBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "app.lumaledger/receipts")
    private val root = File(activity.noBackupFilesDir, "receipt-inbox").apply { mkdirs() }
    private val worker = Executors.newSingleThreadExecutor()
    private val recognizerDelegate = lazy { TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS) }
    private val recognizer by recognizerDelegate
    private val jobs = linkedMapOf<String, MutableMap<String, Any?>>()
    private var error: String? = null
    private var incoming = 0
    private var closed = false
    private val pickerCode = 4831

    init {
        // Pending drafts survive process death. Files expire after 24 hours and
        // are never part of Android cloud backup or Luma's JSON backup.
        root.listFiles()?.filter { it.name.endsWith(".json") }?.sortedBy { it.lastModified() }?.forEach { meta ->
            val id = meta.name.removeSuffix(".json")
            val file = File(root, "$id.image")
            try {
                require(Regex("[a-f0-9-]{36}").matches(id))
                require(System.currentTimeMillis() - meta.lastModified() < 86_400_000)
                require(file.exists())
                val obj = JSONObject(meta.readText())
                val job = mutableMapOf<String, Any?>("id" to id, "path" to file.path,
                    "hash" to obj.optString("hash"), "text" to obj.optString("text"),
                    "reading" to obj.optBoolean("reading"),
                    "error" to if (obj.isNull("error")) null else obj.optString("error"))
                jobs[id] = job
            } catch (_: Exception) { meta.delete(); file.delete() }
        }
        root.listFiles()?.filter { it.extension == "image" && !jobs.containsKey(it.nameWithoutExtension) }?.forEach { it.delete() }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "list" -> result.success(mapOf("items" to jobs.values.toList(), "error" to error))
                "pick" -> {
                    try {
                        activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }, pickerCode)
                        result.success(null)
                    } catch (_: Exception) { result.error("picker", "Image picker unavailable", null) }
                }
                "discard" -> {
                    val id = call.argument<String>("id")
                    if (id != null && jobs.remove(id) != null) {
                        File(root, "$id.json").delete()
                        File(root, "$id.image").delete()
                    }
                    error = null
                    changed()
                    result.success(null)
                }
                // Internal method also enables on-device OCR integration tests.
                // It is not an exported Android component or intent interface.
                "importFile" -> {
                    val path = call.argument<String>("path")
                    if (path == null) result.error("input", "No image selected", null)
                    else { ingest { File(path).inputStream() }; result.success(null) }
                }
                else -> result.notImplemented()
            }
        }
        jobs.values.filter { it["reading"] == true }.toList().forEach { recognize(it) }
    }

    @Suppress("DEPRECATION")
    fun receive(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND || intent.type?.startsWith("image/") != true) return
        val uri = try { intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM) ?: intent.clipData?.getItemAt(0)?.uri }
        catch (_: Exception) { null }
        if (uri == null || uri.scheme != "content") { fail("Could not access the shared image. Share the original receipt again."); return }
        ingest { activity.contentResolver.openInputStream(uri) ?: error("No image stream") }
    }

    fun picked(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != pickerCode || resultCode != Activity.RESULT_OK) return
        val uri = data?.data ?: return
        ingest { activity.contentResolver.openInputStream(uri) ?: error("No image stream") }
    }

    private fun ingest(open: () -> InputStream) {
        if (jobs.size + incoming >= 5) { fail("Your receipt inbox is full. Review or discard a receipt before sharing another."); return }
        incoming++
        error = null
        worker.execute {
            val id = UUID.randomUUID().toString()
            val file = File(root, "$id.image")
            try {
                val digest = MessageDigest.getInstance("SHA-256")
                open().use { input -> file.outputStream().use { output ->
                    val buffer = ByteArray(8192)
                    var total = 0L
                    while (true) {
                        val n = input.read(buffer)
                        if (n < 0) break
                        total += n
                        require(total <= 20L * 1024 * 1024)
                        digest.update(buffer, 0, n)
                        output.write(buffer, 0, n)
                    }
                } }
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(file.path, bounds)
                require(bounds.outWidth > 0 && bounds.outHeight > 0)
                require(bounds.outWidth <= 16000 && bounds.outHeight <= 16000)
                require(bounds.outWidth.toLong() * bounds.outHeight <= 32_000_000)
                val hash = digest.digest().joinToString("") { "%02x".format(it) }
                activity.runOnUiThread {
                    incoming--
                    if (closed || jobs.values.any { it["hash"] == hash }) { file.delete(); changed() }
                    else {
                        val job = mutableMapOf<String, Any?>("id" to id, "path" to file.path,
                            "hash" to hash, "text" to "", "reading" to true, "error" to null)
                        jobs[id] = job
                        persist(job)
                        changed()
                        recognize(job)
                    }
                }
            } catch (_: Exception) {
                file.delete()
                activity.runOnUiThread {
                    incoming--
                    fail("Could not read this image. Share the original PNG or JPEG receipt (up to 20 MB), or choose another image.")
                }
            }
        }
    }

    private fun recognize(job: MutableMap<String, Any?>) {
        worker.execute {
            try {
                val image = InputImage.fromFilePath(activity, Uri.fromFile(File(job["path"] as String)))
                recognizer.process(image).addOnSuccessListener { text ->
                    complete(job, text.text.take(50_000), null)
                }.addOnFailureListener { complete(job, "", "Text could not be read. Try a clearer original receipt image.") }
            } catch (_: Exception) { activity.runOnUiThread { complete(job, "", "This image could not be opened. Choose another image.") } }
        }
    }
    private fun complete(job: MutableMap<String, Any?>, text: String, failure: String?) {
        val id = job["id"] as String
        if (closed || !jobs.containsKey(id)) return
        job["text"] = text
        job["reading"] = false
        job["error"] = failure ?: if (text.isBlank()) "No readable text found. Choose a clearer receipt image." else null
        persist(job)
        changed()
    }
    private fun persist(job: Map<String, Any?>) {
        try { File(root, "${job["id"]}.json").writeText(JSONObject(job).toString()) }
        catch (_: Exception) { fail("The receipt could not be kept on this device. Free some storage and share it again if you close Luma.") }
    }
    private fun fail(message: String) { error = message; changed() }
    private fun changed() { if (!closed) channel.invokeMethod("changed", null) }
    fun close() {
        closed = true
        channel.setMethodCallHandler(null)
        worker.shutdown()
        if (recognizerDelegate.isInitialized()) recognizer.close()
    }
}
