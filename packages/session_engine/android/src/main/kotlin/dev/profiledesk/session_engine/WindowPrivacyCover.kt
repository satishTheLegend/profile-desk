package dev.profiledesk.session_engine

import android.app.Activity
import android.graphics.Color
import android.view.Gravity
import android.view.FocusFinder
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/** Main-thread cover for Flutter content as well as the browser platform view. */
internal class WindowPrivacyCover {
    private var overlay: FrameLayout? = null
    private var obscured = emptyList<Pair<View, Int>>()
    private var protectedWindow: Window? = null
    private var inputGuard: InputGuard? = null
    private class InputGuard(val original: Window.Callback, var shield: InputShield?): Window.Callback by original {
        override fun dispatchKeyEvent(event: KeyEvent): Boolean {
            val cover = shield ?: return original.dispatchKeyEvent(event)
            return if (systemKey(event)) original.dispatchKeyEvent(event) else cover.dispatchKeyEvent(event)
        }
        override fun dispatchKeyShortcutEvent(event: KeyEvent): Boolean =
            if (shield == null || systemKey(event)) original.dispatchKeyShortcutEvent(event) else true
        private fun systemKey(event: KeyEvent) = event.keyCode in intArrayOf(KeyEvent.KEYCODE_BACK,
            KeyEvent.KEYCODE_VOLUME_UP,KeyEvent.KEYCODE_VOLUME_DOWN,KeyEvent.KEYCODE_VOLUME_MUTE)
    }
    private class InputShield(context: android.content.Context): FrameLayout(context) {
        var unlockControl: Button? = null
        override fun dispatchKeyEvent(event: KeyEvent): Boolean {
            val navigation = event.keyCode in intArrayOf(KeyEvent.KEYCODE_TAB,KeyEvent.KEYCODE_DPAD_UP,
                KeyEvent.KEYCODE_DPAD_DOWN,KeyEvent.KEYCODE_DPAD_LEFT,KeyEvent.KEYCODE_DPAD_RIGHT)
            if (navigation) {
                if (event.action == KeyEvent.ACTION_DOWN) {
                    val unlock = unlockControl?.takeIf { it.isEnabled }
                    if (unlock != null) unlock.requestFocus() else requestFocus()
                }
                return true
            }
            if (event.keyCode in intArrayOf(KeyEvent.KEYCODE_ENTER,KeyEvent.KEYCODE_NUMPAD_ENTER,
                KeyEvent.KEYCODE_DPAD_CENTER,KeyEvent.KEYCODE_SPACE)) {
                if (event.action == KeyEvent.ACTION_UP && !event.isCanceled && event.hasNoModifiers()) {
                    unlockControl?.takeIf { it.isEnabled && it.hasFocus() }?.performClick()
                }
                return true
            }
            if (super.dispatchKeyEvent(event)) return true
            // Keep text, shortcuts and tab traversal away from the obscured
            // Flutter/WebView input. System volume/back keys keep OS handling.
            return event.keyCode !in intArrayOf(KeyEvent.KEYCODE_BACK,
                KeyEvent.KEYCODE_VOLUME_UP,KeyEvent.KEYCODE_VOLUME_DOWN,KeyEvent.KEYCODE_VOLUME_MUTE)
        }
        override fun focusSearch(focused: View, direction: Int): View? =
            FocusFinder.getInstance().findNextFocus(this,focused,direction) ?: this
    }

    fun show(activity: Activity?, allowUnlock: Boolean, authenticating: Boolean, unlock: () -> Unit) {
        val root = activity?.window?.decorView as? ViewGroup ?: return
        val previousFocus = activity.currentFocus
        (activity.getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as? InputMethodManager)
            ?.hideSoftInputFromWindow(previousFocus?.windowToken ?: root.windowToken,0)
        previousFocus?.clearFocus()
        if (overlay?.parent !== root) {
            hide()
            val content = InputShield(root.context).apply {
                setBackgroundColor(Color.rgb(244,247,245))
                isClickable = true
                isFocusable = true
                isFocusableInTouchMode = true
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
                // Keep the hierarchy in this window. No overlay permission or
                // separately managed system window is involved.
            }
            obscured = (0 until root.childCount).map { index ->
                root.getChildAt(index).let { it to it.importantForAccessibility }
            }
            obscured.forEach { (view, _) ->
                view.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            }
            overlay = content
            root.addView(content, ViewGroup.LayoutParams(-1,-1))
        }
        val content = overlay ?: return
        content.removeAllViews()
        (content as InputShield).unlockControl = null
        if (allowUnlock) {
            val controls = LinearLayout(root.context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                val inset = (24 * resources.displayMetrics.density).toInt()
                setPadding(inset,inset,inset,inset)
            }
            controls.addView(TextView(root.context).apply {
                setText(R.string.profiledesk_workspace_protected)
                setTextColor(Color.rgb(25,55,45))
                textSize = 22f
                gravity = Gravity.CENTER
            })
            controls.addView(Button(root.context).apply {
                setText(R.string.profiledesk_unlock_title)
                minHeight = (48 * resources.displayMetrics.density).toInt()
                isEnabled = !authenticating
                isFocusableInTouchMode = true
                setOnClickListener { unlock() }
            }.also { content.unlockControl = it })
            content.addView(controls, FrameLayout.LayoutParams(-1,-2,Gravity.CENTER))
        }
        content.bringToFront()
        content.requestFocus()
        if (inputGuard == null) {
            val window = activity.window
            val original = window.callback
            if (original != null) {
                val guard = InputGuard(original,content as InputShield)
                protectedWindow = window
                inputGuard = guard
                window.callback = guard
            }
        }
    }

    fun hide() {
        inputGuard?.let { guard ->
            // A later wrapper may retain ours; disable it in either case, and
            // restore only when we still own the current callback slot.
            guard.shield = null
            if (protectedWindow?.callback === guard) protectedWindow?.callback = guard.original
        }
        inputGuard = null; protectedWindow = null
        overlay?.let { (it.parent as? ViewGroup)?.removeView(it) }
        overlay = null
        obscured.forEach { (view, previous) -> view.importantForAccessibility = previous }
        obscured = emptyList()
    }
}
