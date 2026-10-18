package dev.profiledesk.session_engine

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.view.KeyEvent
import android.widget.Button
import android.widget.FrameLayout
import android.widget.TextView
import android.widget.EditText
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.android.controller.ActivityController
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class WindowPrivacyCoverTest {
    private lateinit var activity: Activity
    private lateinit var controller: ActivityController<Activity>
    private lateinit var root: ViewGroup
    private lateinit var privateContent: TextView
    private val cover = WindowPrivacyCover()
    @Before fun setup() {
        controller = Robolectric.buildActivity(Activity::class.java).setup()
        activity = controller.get()
        privateContent = TextView(activity).apply {
            text = "Fictional native conversation"
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
        }
        activity.setContentView(privateContent)
        root = activity.window.decorView as ViewGroup
    }
    @After fun cleanup() { cover.hide();activity.finish();controller.pause().stop().destroy() }

    @Test fun coversTheWholeWindowAndRestoresAccessibilityWithoutDart() {
        val original = (0 until root.childCount).map { root.getChildAt(it) to root.getChildAt(it).importantForAccessibility }
        cover.show(activity,false,false) {}
        val overlay = root.getChildAt(root.childCount-1) as FrameLayout
        assertEquals(-1,overlay.layoutParams.width)
        assertEquals(-1,overlay.layoutParams.height)
        assertTrue(overlay.isClickable)
        assertTrue(overlay.isFocusable)
        original.forEach { (view,_) -> assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS,view.importantForAccessibility) }
        cover.hide()
        assertNull(overlay.parent)
        original.forEach { (view,importance) -> assertEquals(importance,view.importantForAccessibility) }
        assertEquals("Fictional native conversation",privateContent.text.toString())
    }

    @Test fun aLockedCoverProvidesUnlockAndCannotDuplicateOrLeakAcrossWindows() {
        var unlocks=0
        val originalCount=root.childCount
        cover.show(activity,true,false) { unlocks++ }
        val overlay=root.getChildAt(root.childCount-1) as ViewGroup
        val button=(overlay.getChildAt(0) as ViewGroup).getChildAt(1) as Button
        button.performClick()
        assertEquals(1,unlocks)
        cover.show(activity,true,true) { unlocks++ }
        assertEquals(originalCount+1,root.childCount)
        val disabled=((root.getChildAt(root.childCount-1) as ViewGroup).getChildAt(0) as ViewGroup).getChildAt(1) as Button
        assertFalse(disabled.isEnabled)
        val secondController=Robolectric.buildActivity(Activity::class.java).setup()
        val second=secondController.get()
        try {
            cover.show(second,false,false) {}
            assertEquals(originalCount,root.childCount)
            assertNotSame(root,overlay.parent)
        } finally { cover.hide();second.finish();secondController.pause().stop().destroy() }
    }

    @Test fun nativeCoverEndsInputAndInterceptsKeysWithoutChangingTheDraft() {
        val input=EditText(activity).apply { setText("Owned unsent draft") }
        activity.setContentView(input)
        input.requestFocus()
        assertTrue(input.hasFocus())
        val originalCallback=activity.window.callback
        cover.show(activity,true,false) {}
        val overlay=root.getChildAt(root.childCount-1)
        assertFalse(input.hasFocus())
        assertTrue(overlay.hasFocus())
        // Window.Callback is the native entry point before Activity/Flutter key
        // dispatch, so a delayed Dart handler cannot receive this key.
        assertNotSame(originalCallback,activity.window.callback)
        assertTrue(activity.window.callback.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_A)))
        assertTrue(activity.window.callback.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_UP,KeyEvent.KEYCODE_A)))
        assertTrue(activity.window.callback.dispatchKeyShortcutEvent(KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_A)))
        assertEquals("Owned unsent draft",input.text.toString())
        assertTrue((overlay as ViewGroup).focusSearch(overlay,View.FOCUS_FORWARD)?.isDescendantOf(overlay) != false)
        cover.hide()
        assertSame(originalCallback,activity.window.callback)
        assertEquals("Owned unsent draft",input.text.toString())
    }

    @Test fun callbackKeyboardNavigationActivatesOnlyTheEnabledUnlockControl() {
        var unlocks=0
        cover.show(activity,true,false) { unlocks++ }
        // Complete native layout in the owned viewport before user key events.
        root.measure(View.MeasureSpec.makeMeasureSpec(1080,View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(1920,View.MeasureSpec.EXACTLY))
        root.layout(0,0,1080,1920)
        val callback=activity.window.callback
        assertTrue(callback.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_TAB)))
        assertTrue(callback.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_UP,KeyEvent.KEYCODE_TAB)))
        val overlay=root.getChildAt(root.childCount-1) as ViewGroup
        val button=(overlay.getChildAt(0) as ViewGroup).getChildAt(1) as Button
        // Robolectric's Activity.getCurrentFocus is a separate shadow cache;
        // inspect the actual attached native hierarchy instead of seeding it.
        assertSame(button,root.findFocus())
        assertTrue(button.isFocused)
        assertTrue(callback.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_ENTER)))
        assertTrue(callback.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_UP,KeyEvent.KEYCODE_ENTER)))
        assertEquals(1,unlocks)
        cover.show(activity,true,true) { unlocks++ }
        val disabled=activity.window.callback
        disabled.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_TAB))
        disabled.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_UP,KeyEvent.KEYCODE_ENTER))
        assertEquals(1,unlocks)
        assertFalse(root.findFocus() is Button)
    }

    private fun View.isDescendantOf(ancestor: ViewGroup):Boolean {
        var current:View?=this
        while(current!=null) { if(current===ancestor)return true; current=current.parent as? View }
        return false
    }

    @Test fun enginePauseAndLockCoverNativeContentWithoutAnyWebHost()=runBlocking {
        val context=ApplicationProvider.getApplicationContext<Context>()
        context.deleteDatabase("profiledesk_registry.db")
        val engine=AndroidSessionEngine(context)
        fun field(name:String)=AndroidSessionEngine::class.java.getDeclaredField(name).apply{isAccessible=true}
        try {
            engine.activity=activity
            field("locked").setBoolean(engine,false)
            val originalCount=root.childCount
            engine.onPause()
            assertEquals(originalCount+1,root.childCount)
            engine.onResume()
            assertEquals(originalCount,root.childCount)
            field("initialized").setBoolean(engine,true)
            engine.lockApp()
            assertEquals(originalCount+1,root.childCount)
            engine.onActivityDetached()
            assertEquals(originalCount,root.childCount)
            assertNull(engine.activity)
        } finally {
            engine.onActivityDetached()
            (field("registry").get(engine) as NativeRegistry).close()
            context.deleteDatabase("profiledesk_registry.db")
        }
    }
}
