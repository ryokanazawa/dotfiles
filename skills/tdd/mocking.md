# いつmockするか

mockは**システムの境界**だけに使う:

- 外部API（決済、メールなど）
- データベース（場合による。テストDBを優先）
- 時間・乱数
- ファイルシステム（場合による）

mockしないもの:

- 自分のクラス・モジュール
- 内部のcollaborator
- 自分で管理できるものすべて

## mockしやすい設計

システムの境界では、mockしやすいインターフェースを設計する:

**1. dependency injectionを使う**

外部依存は内部で作らず、外から渡す:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. 汎用fetcherよりSDKスタイルのインターフェースを優先する**

条件分岐を持つ汎用関数1つではなく、外部操作ごとに専用の関数を作る:

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

SDKアプローチの利点:
- 各mockは1つの決まったshapeを返す
- テストのセットアップに条件分岐が要らない
- テストがどのendpointを叩くか分かりやすい
- endpointごとに型安全が得られる
