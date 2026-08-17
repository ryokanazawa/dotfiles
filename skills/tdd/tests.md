# 良いテストと悪いテスト

## 良いテスト

**integrationスタイル**: 内部パーツのmockではなく、実際のインターフェースを通じてテストする。

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

特徴:

- ユーザーや呼び出し側が関心を持つ振る舞いをテストする
- 公開APIだけを使う
- 内部のリファクタリングに耐える
- HOWではなくWHATを表す
- テスト1つにつき論理的なassertionは1つ

## 悪いテスト

**実装詳細のテスト**: 内部構造に結合している。

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

危険信号:

- 内部のcollaboratorをmockする
- privateメソッドをテストする
- 呼び出し回数・順序をassertionする
- 振る舞いが変わっていないのにリファクタリングでテストが壊れる
- テスト名がWHATではなくHOWを表している
- インターフェースではなく外部の手段で検証する

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

**同語反復のテスト**: 期待値が実装の言い換えになっていて、構造的に必ず通る。

```typescript
// BAD: Expected value is recomputed the way the code computes it
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: Expected value is an independent, known literal
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```
