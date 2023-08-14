package io.bimmergestalt.headunit

import androidx.collection.SparseArrayCompat

object Utils {
	fun <E> SparseArrayCompat<E>.values(): List<E> {
		return (0..this.size()).map {
			this.valueAt(it)
		}
	}
}