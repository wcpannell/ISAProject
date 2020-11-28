int add(int *by_ref, int by_val) {
  *by_ref = *by_ref + by_val;
  return by_val;
}

int i = 0;
int j = 20;
int k = 0;
int l[10];

void main(void) {
  for (i = 0; i < 10; i++) {
    l[i] = add(&j, i);
  }
  i = i - j;
  if (i >= 10) {
    j = 0xaa;
  } else {
    j = 0x55;
  }
  k = 0x55a9;
  while ((j & k) != 0) {
    k++;
  }
  i = (j | k) == -1;
  i = j > k;
  i = j <= k;
}
