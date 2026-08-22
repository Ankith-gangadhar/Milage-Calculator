package com.ankithgangadhar.mileagecalculator

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

@Preview(widthDp = 100, heightDp = 100)
@Composable
fun SimplePreview() {
    Box(modifier = Modifier.size(100.dp).background(Color.Red))
}
