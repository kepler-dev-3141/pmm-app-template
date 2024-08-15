package io.github.thisisthepy.pycomposeui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.CoroutineScope
import kotlin.jvm.JvmName


/*
 * Description: Composable Wrapper contains Kotlin Composable can be invoked by Python functions
 */
@JvmName("composableWrapper")
@Composable
fun composableWrapper(content: @Composable (args: Array<Any>) -> Any, args: Array<Any>): Any {
    return content(args)
}

@JvmName("coroutineScopeWrapper")
@Composable
fun coroutineScopeWrapper(): CoroutineScope {
    return rememberCoroutineScope()
}
