'use client'

import { useState } from 'react'
import {
  Car,
  Download,
  ShieldCheck,
  CheckCircle2,
  TrendingUp,
  FileSpreadsheet,
  Lock,
  Building2,
  Mail,
  KeyRound,
  ArrowRight,
  AlertCircle
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

export default function Home() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [galeriAdi, setGaleriAdi] = useState('')
  const [loading, setLoading] = useState(false)
  const [successMsg, setSuccessMsg] = useState('')
  const [errorMsg, setErrorMsg] = useState('')

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setErrorMsg('')
    setSuccessMsg('')

    if (!email || !password || !galeriAdi) {
      setErrorMsg('Lütfen tüm alanları doldurun.')
      return
    }

    if (password.length < 10) {
      setErrorMsg('Şifreniz güvenliğiniz için en az 10 karakter olmalıdır.')
      return
    }

    setLoading(true)

    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            galeri_adi: galeriAdi,
          },
        },
      })

      if (error) throw error

      if (data.user) {
        // Eğer session yoksa email doğrulaması gerekir, session varsa direkt oturum açılmıştır
        if (!data.session) {
          setSuccessMsg(
            'Kayıt oluşturuldu! Lütfen e-posta adresinize gönderilen aktivasyon linkine tıklayın. Ardından masaüstü uygulamasından giriş yapabilirsiniz.'
          )
        } else {
          // Doğrudan profil satırı oluştur
          try {
            await supabase.from('profiles').insert({
              id: data.user.id,
              galeri_adi: galeriAdi,
            })
          } catch (_) {
            // Trigger varsa duplicate hatası verebilir, sorun değil
          }

          setSuccessMsg(
            'Tebrikler, hesabınız oluşturuldu! Şimdi Windows uygulamasını indirip doğrudan giriş yapabilirsiniz.'
          )
        }
        setEmail('')
        setPassword('')
        setGaleriAdi('')
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col font-sans">
      {/* Header / Nav */}
      <header className="border-b border-slate-200 bg-white/80 backdrop-blur sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center text-white shadow-md shadow-blue-500/20">
              <Car className="w-6 h-6" />
            </div>
            <span className="font-bold text-xl tracking-tight text-slate-900">
              Galeri<span className="text-blue-600">Pro</span>
            </span>
          </div>

          <div className="flex items-center space-x-4">
            <a
              href="#kayit"
              className="text-sm font-semibold text-slate-600 hover:text-blue-600 transition"
            >
              Kayıt Ol
            </a>
            <a
              href="https://sfcumafkxhndjuukbodn.supabase.co/storage/v1/object/public/downloads/GaleriPro-Windows.zip"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center space-x-2 text-sm font-semibold bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition shadow-sm"
            >
              <Download className="w-4 h-4" />
              <span>İndir</span>
            </a>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <main className="flex-1">
        <section className="py-16 md:py-24 px-4 max-w-6xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Sol Taraf: Tanıtım ve Bilgi */}
            <div className="lg:col-span-7 space-y-6">
              <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-blue-50 text-blue-700 text-xs font-semibold tracking-wide border border-blue-200">
                <ShieldCheck className="w-4 h-4 text-blue-600" />
                <span>Windows Masaüstü & Güvenli Bulut Altyapısı</span>
              </div>

              <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-slate-900 leading-tight">
                Oto Galeriniz İçin <br />
                <span className="text-blue-600">Akıllı & Hızlı</span> Takip Sistemi
              </h1>

              <p className="text-lg text-slate-600 leading-relaxed max-w-xl">
                Araç alım-satım süreçlerinizi, kâr/zarar durumunuzu, masraflarınızı ve müşteri kayıtlarınızı tek bir güvenli masaüstü yazılımında yönetin.
              </p>

              {/* Hızlı Özellik İkonları */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4">
                <div className="flex items-start space-x-3 bg-white p-4 rounded-xl border border-slate-200/80 shadow-sm">
                  <TrendingUp className="w-5 h-5 text-blue-600 mt-0.5" />
                  <div>
                    <h2 className="font-semibold text-sm text-slate-900">Otomatik Kâr Hesabı</h2>
                    <p className="text-xs text-slate-500 mt-1">
                      Alış, satış ve tüm araç masraflarını net kâr/zarar olarak anında görün.
                    </p>
                  </div>
                </div>

                <div className="flex items-start space-x-3 bg-white p-4 rounded-xl border border-slate-200/80 shadow-sm">
                  <FileSpreadsheet className="w-5 h-5 text-emerald-600 mt-0.5" />
                  <div>
                    <h2 className="font-semibold text-sm text-slate-900">Excel & PDF Raporları</h2>
                    <p className="text-xs text-slate-500 mt-1">
                      Tek tıkla resmi muhasebe ve stok çıktıları alın, yazdırın veya paylaşın.
                    </p>
                  </div>
                </div>
              </div>

              {/* İndirme Butonu Alanı */}
              <div id="indir" className="pt-6">
                <a
                  href="https://sfcumafkxhndjuukbodn.supabase.co/storage/v1/object/public/downloads/GaleriPro-Windows.zip"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center space-x-3 bg-slate-900 hover:bg-slate-800 text-white px-6 py-3.5 rounded-xl font-semibold shadow-lg shadow-slate-900/10 transition transform active:scale-95"
                >
                  <Download className="w-5 h-5 text-blue-400" />
                  <div className="text-left">
                    <div className="text-xs text-slate-400">Windows için hazır (16.4 MB)</div>
                    <div className="text-sm font-bold">GaleriPro v1.0 İndir (.zip)</div>
                  </div>
                </a>
                <p className="text-xs text-slate-400 mt-2">
                  * İndirilen zip dosyasını klasöre çıkartıp içindeki <strong>oto_galeri_app.exe</strong> dosyasına çift tıklayarak hemen kullanabilirsiniz.
                </p>
              </div>
            </div>

            {/* Sağ Taraf: Kayıt Formu */}
            <div id="kayit" className="lg:col-span-5">
              <div className="bg-white rounded-2xl border border-slate-200 shadow-xl p-8 relative overflow-hidden">
                <div className="absolute top-0 left-0 right-0 h-1.5 bg-gradient-to-r from-blue-500 to-indigo-600" />

                <div className="mb-6">
                  <h2 className="text-2xl font-bold text-slate-900">Yeni Hesap Oluşturun</h2>
                  <p className="text-sm text-slate-500 mt-1">
                    Buradan kayıt olduktan sonra bilgilerinizi masaüstü uygulamasında kullanabilirsiniz.
                  </p>
                </div>

                {errorMsg && (
                  <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg flex items-start space-x-2">
                    <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
                    <span>{errorMsg}</span>
                  </div>
                )}

                {successMsg && (
                  <div className="mb-4 p-3 bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm rounded-lg flex items-start space-x-2">
                    <CheckCircle2 className="w-4 h-4 mt-0.5 flex-shrink-0 text-emerald-600" />
                    <span>{successMsg}</span>
                  </div>
                )}

                <form onSubmit={handleRegister} className="space-y-4">
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                      Galeri Adı
                    </label>
                    <div className="relative">
                      <Building2 className="w-5 h-5 text-slate-400 absolute left-3 top-3" />
                      <input
                        type="text"
                        required
                        value={galeriAdi}
                        onChange={(e) => setGaleriAdi(e.target.value)}
                        placeholder="Örn: Yıldız Motors"
                        className="w-full pl-10 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-600 focus:bg-white transition"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                      E-Posta Adresi
                    </label>
                    <div className="relative">
                      <Mail className="w-5 h-5 text-slate-400 absolute left-3 top-3" />
                      <input
                        type="email"
                        required
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        placeholder="galeri@ornek.com"
                        className="w-full pl-10 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-600 focus:bg-white transition"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                      Şifre (En az 10 karakter)
                    </label>
                    <div className="relative">
                      <KeyRound className="w-5 h-5 text-slate-400 absolute left-3 top-3" />
                      <input
                        type="password"
                        required
                        minLength={10}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="••••••••••"
                        className="w-full pl-10 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-600 focus:bg-white transition"
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full mt-2 inline-flex items-center justify-center space-x-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-semibold py-3 rounded-lg transition shadow-md shadow-blue-500/20"
                  >
                    {loading ? (
                      <span>Kaydediliyor...</span>
                    ) : (
                      <>
                        <span>Ücretsiz Kayıt Ol</span>
                        <ArrowRight className="w-4 h-4" />
                      </>
                    )}
                  </button>
                </form>

                <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-center space-x-2 text-xs text-slate-400">
                  <Lock className="w-3.5 h-3.5" />
                  <span>Verileriniz 256-bit SSL ve Supabase ile korunmaktadır.</span>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-200 bg-white py-6">
        <div className="max-w-6xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-4">
          <div>© 2026 GaleriPro. Tüm hakları saklıdır.</div>
          <div className="flex items-center space-x-6">
            <span>Güvenli Bulut Altyapısı</span>
            <span>Windows Desktop Edition</span>
          </div>
        </div>
      </footer>
    </div>
  )
}
