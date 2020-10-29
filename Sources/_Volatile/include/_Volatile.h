/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
static inline int volatile_load_int(void *i) {
  return *(volatile int*)i;
}

static inline void volatile_store_int(void *i, int value) {
  *(volatile int*)i = value;
}
