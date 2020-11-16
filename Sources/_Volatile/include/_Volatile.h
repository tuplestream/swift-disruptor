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

static inline long long volatile_load_long_long(void *l) {
    return *(volatile long long*)l;
}

static inline void volatile_store_long_long(void *l, long long value) {
    *(volatile long long*)l = value;
}
