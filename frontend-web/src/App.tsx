import { useMemo, useState } from 'react'
import { apiBaseUrl, apiGetText } from './lib/api'

function App() {
  const api = useMemo(() => apiBaseUrl(), [])
  const [ping, setPing] = useState<string>('')
  const [error, setError] = useState<string>('')

  async function onPing() {
    setError('')
    setPing('')
    try {
      // This is a generic example endpoint; adjust to your Laravel routes.
      const text = await apiGetText('/api')
      setPing(text.slice(0, 500))
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    }
  }

  return (
    <div className="min-h-full bg-slate-950 text-slate-100">
      <div className="mx-auto max-w-4xl px-6 py-10">
        <header className="space-y-2">
          <div className="inline-flex items-center gap-2 rounded-full bg-slate-800/60 px-3 py-1 text-sm text-slate-200 ring-1 ring-white/10">
            <span className="font-semibold">FitSocial</span>
            <span className="text-slate-400">frontend-web</span>
          </div>
          <h1 className="text-3xl font-semibold tracking-tight">
            React + Tailwind (Vite)
          </h1>
          <p className="text-slate-300">
            App này sẽ gọi API Laravel backend để dùng chung database.
          </p>
        </header>

        <main className="mt-8 grid gap-6 md:grid-cols-2">
          <section className="rounded-2xl bg-slate-900/60 p-5 ring-1 ring-white/10">
            <h2 className="text-lg font-semibold">API config</h2>
            <p className="mt-2 text-sm text-slate-300">
              Base URL (từ <code className="rounded bg-white/10 px-1">VITE_API_BASE_URL</code>):
            </p>
            <div className="mt-2 break-all rounded-xl bg-black/30 p-3 font-mono text-sm text-slate-200 ring-1 ring-white/10">
              {api}
            </div>
            <p className="mt-3 text-sm text-slate-400">
              Mặc định dev sẽ trỏ về <code className="rounded bg-white/10 px-1">http://127.0.0.1:8000</code>.
            </p>
          </section>

          <section className="rounded-2xl bg-slate-900/60 p-5 ring-1 ring-white/10">
            <h2 className="text-lg font-semibold">Quick ping</h2>
            <p className="mt-2 text-sm text-slate-300">
              Nút này thử gọi <code className="rounded bg-white/10 px-1">GET /api</code> (chỉ ví dụ).
            </p>
            <div className="mt-4 flex items-center gap-3">
              <button
                className="rounded-xl bg-indigo-500 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-400 focus:outline-none focus:ring-2 focus:ring-indigo-300/60"
                onClick={onPing}
                type="button"
              >
                Ping backend
              </button>
              {error ? (
                <span className="text-sm text-red-300">{error}</span>
              ) : null}
            </div>
            {ping ? (
              <pre className="mt-4 max-h-64 overflow-auto rounded-xl bg-black/30 p-3 text-xs text-slate-200 ring-1 ring-white/10">
                {ping}
              </pre>
            ) : null}
          </section>
        </main>

        <footer className="mt-10 text-sm text-slate-500">
          Tip: tạo file <code className="rounded bg-white/10 px-1">.env.local</code> để override API base URL.
        </footer>
      </div>
    </div>
  )
}

export default App
