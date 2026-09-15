package com.videos16mb.app

import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Base64
import android.webkit.JavascriptInterface
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.webkit.WebViewAssetLoader

class MainActivity : Activity() {

    private lateinit var web: WebView
    private var pickerCallback: ValueCallback<Array<Uri>>? = null

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Sirve la web desde los assets con origen https seguro:
        // así el motor FFmpeg (workers) funciona igual que en el escritorio.
        val assetLoader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()

        web = WebView(this)
        web.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
            mediaPlaybackRequiresUserGesture = false
            cacheMode = WebSettings.LOAD_DEFAULT
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
        }
        web.setBackgroundColor(0xFF0A0F1E.toInt())
        web.addJavascriptInterface(PuenteAndroid(), "AndroidPuente")

        web.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(
                view: WebView,
                request: WebResourceRequest
            ): WebResourceResponse? = assetLoader.shouldInterceptRequest(request.url)
        }

        web.webChromeClient = object : WebChromeClient() {
            override fun onShowFileChooser(
                webView: WebView,
                callback: ValueCallback<Array<Uri>>,
                params: FileChooserParams
            ): Boolean {
                pickerCallback?.onReceiveValue(null)
                pickerCallback = callback
                return try {
                    startActivityForResult(
                        Intent.createChooser(params.createIntent(), "Elige un video"),
                        CODIGO_PICKER
                    )
                    true
                } catch (e: Exception) {
                    pickerCallback = null
                    false
                }
            }
        }

        setContentView(web)
        web.loadUrl("https://appassets.androidplatform.net/assets/web/index.html")
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == CODIGO_PICKER) {
            val uris = WebChromeClient.FileChooserParams.parseResult(resultCode, data)
            pickerCallback?.onReceiveValue(uris)
            pickerCallback = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (web.canGoBack()) web.goBack() else super.onBackPressed()
    }

    /**
     * Puente JavaScript → Android.
     * La web llama a AndroidPuente.guardarDescarga(nombre, base64) para
     * guardar los videos procesados en Descargas/Videos16MB.
     */
    inner class PuenteAndroid {
        @JavascriptInterface
        fun guardarDescarga(nombre: String, base64: String): Boolean {
            return try {
                val bytes = Base64.decode(base64, Base64.DEFAULT)
                if (bytes.isEmpty()) return false
                val valores = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, sanitizar(nombre))
                    put(MediaStore.Downloads.MIME_TYPE, "video/mp4")
                    put(
                        MediaStore.Downloads.RELATIVE_PATH,
                        Environment.DIRECTORY_DOWNLOADS + "/Videos16MB"
                    )
                }
                val uri = contentResolver.insert(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI, valores
                ) ?: return false
                contentResolver.openOutputStream(uri)?.use { salida ->
                    salida.write(bytes)
                    salida.flush()
                } ?: return false
                runOnUiThread {
                    Toast.makeText(
                        this@MainActivity,
                        "Guardado en Descargas/Videos16MB: ${sanitizar(nombre)}",
                        Toast.LENGTH_LONG
                    ).show()
                }
                true
            } catch (e: Exception) {
                runOnUiThread {
                    Toast.makeText(
                        this@MainActivity,
                        "No se pudo guardar: ${e.message}",
                        Toast.LENGTH_LONG
                    ).show()
                }
                false
            }
        }

        @JavascriptInterface
        fun versionApp(): String = "1.0"

        private fun sanitizar(n: String): String =
            n.replace(Regex("[\\\\/:*?\"<>|]"), "_").take(120).ifBlank { "video.mp4" }
    }

    companion object {
        private const val CODIGO_PICKER = 42
    }
}
