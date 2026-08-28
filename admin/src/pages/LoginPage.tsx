import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { loginAdmin, ApiError } from '../api/client';
import { useAuth } from '../context/AuthContext';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const admin = await loginAdmin(identifier.trim(), password);
      login(admin);
      navigate('/', { replace: true });
    } catch (err) {
      setError(
        err instanceof ApiError
          ? err.message
          : 'Connexion impossible. Vérifiez vos identifiants.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <form className="login-card" onSubmit={handleSubmit}>
        <div className="login-logo">K</div>
        <h1 className="login-title">Kivoo Admin</h1>
        <p className="login-subtitle">
          Connectez-vous avec votre compte administrateur
        </p>

        {error && <div className="error-banner">{error}</div>}

        <div className="form-field" style={{ marginBottom: 14 }}>
          <label className="form-label" htmlFor="identifier">
            Email ou téléphone
          </label>
          <input
            id="identifier"
            className="input"
            type="text"
            autoComplete="username"
            placeholder="admin@kivoo.com"
            value={identifier}
            onChange={(e) => setIdentifier(e.target.value)}
            required
          />
        </div>

        <div className="form-field" style={{ marginBottom: 20 }}>
          <label className="form-label" htmlFor="password">
            Mot de passe
          </label>
          <input
            id="password"
            className="input"
            type="password"
            autoComplete="current-password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>

        <button className="btn btn-primary" type="submit" disabled={loading} style={{ width: '100%' }}>
          {loading ? 'Connexion...' : 'Se connecter'}
        </button>

        <div className="login-hint">
          Le compte admin est créé via le seed backend
          <br />
          (ADMIN_EMAIL / ADMIN_PASSWORD)
        </div>
      </form>
    </div>
  );
}
