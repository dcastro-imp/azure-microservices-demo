import { useEffect, useState, useCallback } from 'react'
import './App.css'

// Injected at build time (see Dockerfile) — points to the productsapi Container App.
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'

function StatusBadge({ label, value, tone = 'neutral' }) {
  return (
    <div className={`status-card status-${tone}`}>
      <div className="status-label">{label}</div>
      <div className="status-value">{value}</div>
    </div>
  )
}

function OrderTimeline({ orderId, apiUrl }) {
  const [events, setEvents] = useState([])

  useEffect(() => {
    let cancelled = false
    async function load() {
      const res = await fetch(`${apiUrl}/api/orders/${orderId}/events`)
      const data = await res.json()
      if (!cancelled) setEvents(data)
    }
    load()
    const interval = setInterval(load, 3000)
    return () => { cancelled = true; clearInterval(interval) }
  }, [orderId, apiUrl])

  if (events.length === 0) return <span className="timeline-empty">Sin eventos aún…</span>

  return (
    <ul className="timeline">
      {events.map(e => (
        <li key={e.id}><strong>{e.eventType}</strong> — {new Date(e.createdAt).toLocaleTimeString()}</li>
      ))}
    </ul>
  )
}

function App() {
  const [products, setProducts] = useState([])
  const [orders, setOrders] = useState([])
  const [status, setStatus] = useState(null)
  const [form, setForm] = useState({ name: '', category: '', price: '', stock: '' })
  const [orderForm, setOrderForm] = useState({ productId: '', quantity: '' })
  const [expandedOrderId, setExpandedOrderId] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const loadProducts = useCallback(async () => {
    const res = await fetch(`${API_URL}/api/products`)
    setProducts(await res.json())
  }, [])

  const loadOrders = useCallback(async () => {
    const res = await fetch(`${API_URL}/api/orders`)
    setOrders(await res.json())
  }, [])

  const loadStatus = useCallback(async () => {
    const res = await fetch(`${API_URL}/api/status`)
    setStatus(await res.json())
  }, [])

  const refreshAll = useCallback(async () => {
    setError(null)
    try {
      await Promise.all([loadProducts(), loadOrders(), loadStatus()])
    } catch (err) {
      setError('No se pudo conectar con la API: ' + err.message)
    }
  }, [loadProducts, loadOrders, loadStatus])

  async function handleOrderSubmit(e) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      const res = await fetch(`${API_URL}/api/orders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          productId: parseInt(orderForm.productId, 10),
          quantity: parseInt(orderForm.quantity, 10)
        })
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      setOrderForm({ productId: '', quantity: '' })
      await refreshAll()
    } catch (err) {
      setError('Error creando el pedido: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  const statusColor = {
    Pending: 'busy', StockReserved: 'busy', Shipped: 'ok', Failed: 'error'
  }

  useEffect(() => {
    refreshAll()
    // Poll every 5s so you can watch async processing (Service Bus counters)
    // change in near-real-time without manually refreshing.
    const interval = setInterval(refreshAll, 5000)
    return () => clearInterval(interval)
  }, [refreshAll])

  async function handleSubmit(e) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      const res = await fetch(`${API_URL}/api/products`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: form.name,
          category: form.category,
          price: parseFloat(form.price),
          stock: parseInt(form.stock, 10)
        })
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      setForm({ name: '', category: '', price: '', stock: '' })
      await refreshAll()
    } catch (err) {
      setError('Error creando el producto: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="dashboard">
      <h1>Microservices Dashboard</h1>
      <p className="subtitle">
        productsapi → Service Bus Topic → inventory-worker / notification-worker
      </p>

      {error && <div className="error-banner">{error}</div>}

      <section>
        <h2>Estado de la arquitectura</h2>
        <div className="status-grid">
          <StatusBadge
            label="Base de datos"
            value={status?.database?.connected ? 'Conectada' : 'Desconectada'}
            tone={status?.database?.connected ? 'ok' : 'error'}
          />
          <StatusBadge label="Productos en DB" value={status?.database?.productCount ?? '—'} />
          <StatusBadge
            label="inventory-sub: activos"
            value={status?.serviceBus?.inventorySubscription?.activeMessages ?? '—'}
            tone={status?.serviceBus?.inventorySubscription?.activeMessages > 0 ? 'busy' : 'ok'}
          />
          <StatusBadge
            label="inventory-sub: dead-letter"
            value={status?.serviceBus?.inventorySubscription?.deadLetterMessages ?? '—'}
            tone={status?.serviceBus?.inventorySubscription?.deadLetterMessages > 0 ? 'error' : 'ok'}
          />
          <StatusBadge
            label="notification-sub: activos"
            value={status?.serviceBus?.notificationSubscription?.activeMessages ?? '—'}
            tone={status?.serviceBus?.notificationSubscription?.activeMessages > 0 ? 'busy' : 'ok'}
          />
          <StatusBadge
            label="notification-sub: dead-letter"
            value={status?.serviceBus?.notificationSubscription?.deadLetterMessages ?? '—'}
            tone={status?.serviceBus?.notificationSubscription?.deadLetterMessages > 0 ? 'error' : 'ok'}
          />
        </div>
      </section>

      <section>
        <h2>Crear producto</h2>
        <form onSubmit={handleSubmit} className="product-form">
          <input
            placeholder="Nombre"
            value={form.name}
            onChange={e => setForm({ ...form, name: e.target.value })}
            required
          />
          <input
            placeholder="Categoría"
            value={form.category}
            onChange={e => setForm({ ...form, category: e.target.value })}
            required
          />
          <input
            type="number" step="0.01"
            placeholder="Precio"
            value={form.price}
            onChange={e => setForm({ ...form, price: e.target.value })}
            required
          />
          <input
            type="number"
            placeholder="Stock"
            value={form.stock}
            onChange={e => setForm({ ...form, stock: e.target.value })}
            required
          />
          <button type="submit" disabled={loading}>
            {loading ? 'Creando...' : 'Crear (publica evento ProductCreated)'}
          </button>
        </form>
      </section>

      <section>
        <h2>Hacer un pedido</h2>
        <form onSubmit={handleOrderSubmit} className="product-form">
          <select
            value={orderForm.productId}
            onChange={e => setOrderForm({ ...orderForm, productId: e.target.value })}
            required
          >
            <option value="">Selecciona un producto</option>
            {products.map(p => (
              <option key={p.id} value={p.id}>{p.name} (stock: {p.stock})</option>
            ))}
          </select>
          <input
            type="number"
            placeholder="Cantidad"
            value={orderForm.quantity}
            onChange={e => setOrderForm({ ...orderForm, quantity: e.target.value })}
            required
          />
          <button type="submit" disabled={loading}>
            {loading ? 'Procesando...' : 'Pedir (publica OrderCreated)'}
          </button>
        </form>
      </section>

      <section>
        <h2>Pedidos ({orders.length})</h2>
        <table className="products-table">
          <thead>
            <tr><th>ID</th><th>Producto</th><th>Cant.</th><th>Estado</th><th>Timeline</th></tr>
          </thead>
          <tbody>
            {orders.map(o => (
              <tr key={o.id}>
                <td>{o.id}</td><td>{o.productName}</td><td>{o.quantity}</td>
                <td><span className={`badge badge-${statusColor[o.status] || 'neutral'}`}>{o.status}</span></td>
                <td>
                  <button
                    className="link-btn"
                    onClick={() => setExpandedOrderId(expandedOrderId === o.id ? null : o.id)}
                  >
                    {expandedOrderId === o.id ? 'Ocultar' : 'Ver'}
                  </button>
                  {expandedOrderId === o.id && <OrderTimeline orderId={o.id} apiUrl={API_URL} />}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section>
        <h2>Productos ({products.length})</h2>
        <table className="products-table">
          <thead>
            <tr><th>ID</th><th>Nombre</th><th>Categoría</th><th>Precio</th><th>Stock</th></tr>
          </thead>
          <tbody>
            {products.map(p => (
              <tr key={p.id}>
                <td>{p.id}</td><td>{p.name}</td><td>{p.category}</td>
                <td>${p.price}</td><td>{p.stock}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  )
}

export default App
