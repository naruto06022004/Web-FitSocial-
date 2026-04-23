const DEFAULT_API_BASE_URL = 'http://127.0.0.1:8000'

export function apiBaseUrl(): string {
  const raw = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? ''
  const base = raw.trim() || DEFAULT_API_BASE_URL
  return base.replace(/\/+$/, '')
}

export async function apiGetText(path: string): Promise<string> {
  const url = new URL(path.replace(/^\/+/, ''), `${apiBaseUrl()}/`)
  const res = await fetch(url, {
    method: 'GET',
    headers: {
      Accept: 'text/plain, application/json;q=0.9, */*;q=0.8',
    },
  })

  const text = await res.text()
  if (!res.ok) {
    throw new Error(`Request failed (${res.status}): ${text || res.statusText}`)
  }
  return text
}

