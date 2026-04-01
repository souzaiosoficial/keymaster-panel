# 🔑 KeyMaster — Guia Completo de Instalação

Sistema completo de licenciamento para dylibs injetáveis via GBox/ESign.

---

## 📁 Estrutura do Projeto

```
keymaster/
├── server.js          ← Servidor principal
├── db.js              ← Banco de dados SQLite
├── package.json
├── railway.toml       ← Config de deploy
├── .env.example       ← Variáveis de ambiente
├── middleware/
│   └── auth.js
├── routes/
│   ├── admin.js       ← Rotas do painel
│   └── api.js         ← API pública (usada pela dylib)
├── public/
│   ├── index.html     ← Painel admin
│   └── login.html     ← Tela de login
└── dylib/
    ├── Tweak.xm       ← Código da dylib
    └── Makefile
```

---

## 🖥️ ETAPA 1 — Configurar o Servidor no Ubuntu

### 1.1 Instalar Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v   # deve mostrar v20.x.x
```

### 1.2 Instalar dependências

```bash
cd keymaster
npm install
```

### 1.3 Testar localmente

```bash
node server.js
# Abra http://localhost:3000
# Login padrão: admin / admin123
```

---

## ☁️ ETAPA 2 — Deploy gratuito no Railway

### 2.1 Criar conta no Railway

1. Acesse https://railway.app e crie uma conta gratuita (pode usar GitHub).

### 2.2 Instalar a CLI do Railway no Ubuntu

```bash
curl -fsSL https://railway.app/install.sh | sh
```

### 2.3 Fazer login

```bash
railway login
```

### 2.4 Criar projeto e fazer deploy

```bash
cd keymaster
git init
git add .
git commit -m "KeyMaster init"
railway init       # Crie um novo projeto
railway up         # Faz o deploy
```

### 2.5 Configurar variáveis de ambiente no Railway

No painel do Railway (https://railway.app), vá em:
**Seu Projeto → Variables** e adicione:

| Variável         | Valor                          |
|------------------|--------------------------------|
| `SESSION_SECRET` | `uma-string-aleatoria-longa`   |
| `ADMIN_USER`     | `admin`                        |
| `ADMIN_PASS`     | `SuaSenhaForte!`               |
| `PORT`           | `3000`                         |

### 2.6 Obter a URL pública

No Railway vá em **Settings → Networking → Generate Domain**.
Você receberá algo como: `https://keymaster-production.up.railway.app`

> **Guarde essa URL — você vai usá-la na dylib!**

---

## 📱 ETAPA 3 — Compilar a Dylib

### 3.1 Instalar Theos no Ubuntu (cross-compiler para iOS)

```bash
sudo apt-get install -y git curl make
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
# Siga as instruções e defina THEOS=/opt/theos
```

Adicione ao `~/.bashrc`:
```bash
export THEOS=/opt/theos
export PATH=$THEOS/bin:$PATH
source ~/.bashrc
```

### 3.2 Editar a URL do servidor na dylib

Abra `dylib/Tweak.xm` e altere a linha:
```objc
static NSString *const kServerURL = @"https://SEU_DOMINIO_RAILWAY.up.railway.app";
```
Para a sua URL real do Railway.

### 3.3 Compilar

```bash
cd dylib
make
```

O arquivo `.dylib` será gerado em `./packages/` ou `.theos/obj/`.

---

## 💉 ETAPA 4 — Injetar via ESign / GBox

### Via ESign:
1. Abra o ESign no iPhone
2. Importe o `.ipa` do app alvo
3. Vá em **Inject** → selecione o `.dylib` compilado
4. Assine com seu certificado e instale

### Via GBox:
1. Abra o GBox
2. Adicione o `.ipa` do app
3. Na opção de modificação, adicione o `.dylib`
4. Instale normalmente

---

## 🔑 ETAPA 5 — Usando o Painel Admin

### Criar uma key:
1. Acesse `https://sua-url.railway.app`
2. Login com seu usuário e senha
3. Clique em **+ Nova Key**
4. Defina duração (1d / 7d / 30d / Permanente) e máx. dispositivos
5. Clique em **Gerar Key** — ela será copiada automaticamente

### Gerenciar keys:
- 📋 **Copiar** — copia a key para área de transferência
- 📱 **Devices** — vê todos os dispositivos vinculados
- 🔒 **Bloquear/Desbloquear** — suspende ou reativa a key
- ♻️ **Resetar** — remove todos os devices (permite reativar em outro device)
- 🗑️ **Excluir** — apaga a key permanentemente

---

## 🔌 API Endpoint (para referência)

### `POST /api/validate`

**Body:**
```json
{
  "key": "XXXXX-XXXXX-XXXXX-XXXXX",
  "udid": "device-unique-id",
  "device_name": "iPhone de João"
}
```

**Resposta (válida):**
```json
{
  "valid": true,
  "message": "OK",
  "expires_at": "2024-12-31 23:59:59"
}
```

**Resposta (inválida):**
```json
{
  "valid": false,
  "message": "Key bloqueada."
}
```

---

## ⚠️ Notas Importantes

- O banco de dados SQLite é salvo localmente no Railway.
  Para persistência permanente, considere usar Railway com **PostgreSQL** (também gratuito).
- Troque a senha padrão `admin123` **antes** de fazer o deploy.
- O Railway gratuito dorme após 30 dias de inatividade — mantenha ativo com requisições regulares.

---

## 🆘 Suporte

Se a compilação falhar por falta do SDK do iOS:
```bash
# Baixe o SDK manualmente
mkdir -p $THEOS/sdks
cd $THEOS/sdks
wget https://github.com/theos/sdks/releases/download/latest/iPhoneOS16.5.sdk.tar.xz
tar -xf iPhoneOS16.5.sdk.tar.xz
```
