package dev.profiledesk.session_engine

import android.app.Activity
import android.os.Bundle
import android.widget.FrameLayout

/** Real window lifecycle for the synthetic store persistence test; test APK only. */
class SyntheticHostActivity:Activity(){
    lateinit var frame:FrameLayout
        private set
    override fun onCreate(state:Bundle?){
        super.onCreate(state)
        frame=FrameLayout(this)
        setContentView(frame)
    }
}
