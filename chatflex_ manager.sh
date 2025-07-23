#!/bin/bash

# ChatFlex - Script de Gerenciamento Completo
# Versão: 1.0
# Descrição: Instala, configura e limpa o sistema ChatFlex (atendimento WhatsApp)

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_clean() {
    echo -e "${CYAN}[CLEAN]${NC} $1"
}

# Função para confirmar ação
confirm_action() {
    local message="$1"
    local default="${2:-n}" # n como padrão, a menos que y seja explicitamente passado
    
    if [ "$default" = "y" ]; then
        read -p "$message [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            return 1
        fi
        return 0
    else
        read -p "$message [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
        return 1
    fi
}

# ===============================================
# FUNÇÕES DE INSTALAÇÃO
# ===============================================

# Detectar sistema operacional
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
}

# Atualizar Node.js automaticamente
update_nodejs() {
    log_info "Atualizando Node.js para versão 18..."
    
    detect_os
    
    case $OS in
        "debian")
            log_info "Instalando Node.js 18 via NodeSource (Ubuntu/Debian)..."
            sudo apt-get remove -y nodejs npm 2>/dev/null || true
            sudo apt-get update -qq
            sudo apt-get install -y ca-certificates curl gnupg -qq
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs -qq
            ;;
        "redhat")
            log_info "Instalando Node.js 18 via NodeSource (CentOS/RHEL)..."
            sudo yum install -y epel-release 2>/dev/null || sudo dnf install -y epel-release 2>/dev/null || true
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo yum install -y nodejs 2>/dev/null || sudo dnf install -y nodejs
            ;;
        "macos")
            log_info "Instalando Node.js 18 para macOS..."
            if command -v brew &> /dev/null; then
                brew install node@18
                brew link node@18 --force
            else
                log_warning "Homebrew não encontrado. Usando instalação via NVM..."
                install_nodejs_via_nvm
            fi
            ;;
        *)
            log_info "Sistema não detectado automaticamente. Usando NVM..."
            install_nodejs_via_nvm
            ;;
    esac
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    source ~/.bashrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true
    
    if command -v node &> /dev/null; then
        UPDATED_NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$UPDATED_NODE_VERSION" -ge 18 ]; then
            log_success "Node.js $(node --version) atualizado com sucesso!"
            export NODE_UPDATED=1
        else
            log_error "Falha na atualização. Versão atual: $(node --version)"
            log_info "Tente executar primeiro: source ~/.bashrc && nvm use 18"
            exit 1
        fi
    else
        log_error "Node.js não encontrado após instalação"
        log_info "Reinicie o terminal e execute: source ~/.bashrc"
        exit 1
    fi
}

# Instalar Node.js via NVM (método universal)
install_nodejs_via_nvm() {
    log_info "Instalando Node.js 18 via NVM..."
    
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    nvm install 18
    nvm use 18
    nvm alias default 18
}

# Verificar pré-requisitos para instalação
check_install_prerequisites() {
    log_info "Verificando pré-requisitos para instalação..."
    
    if ! command -v node &> /dev/null; then
        log_warning "Node.js não encontrado."
        if confirm_action "Deseja instalar Node.js 18 automaticamente?"; then
            update_nodejs
        else
            log_error "Node.js é necessário para continuar. Instale manualmente: https://nodejs.org"
            exit 1
        fi
    else
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 18 ]; then
            log_warning "Node.js versão 18 ou superior é necessária. Versão atual: $(node --version)"
            if confirm_action "Deseja atualizar Node.js para versão 18 automaticamente?"; then
                update_nodejs
            else
                log_error "Atualize o Node.js manualmente para versão 18+ e execute novamente."
                log_info "Ou execute: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
                exit 1
            fi
        fi
    fi
    
    source ~/.bashrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true
    hash -r 2>/dev/null || true
    
    if ! command -v node &> /dev/null; then
        log_error "Falha na instalação/atualização do Node.js. Reinicie o terminal e execute novamente."
        log_info "Ou execute manualmente: source ~/.bashrc && nvm use 18"
        exit 1
    fi
    
    FINAL_NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$FINAL_NODE_VERSION" -lt 18 ]; then
        log_error "Falha na atualização do Node.js. Versão atual: $(node --version)"
        log_info "Tente executar: nvm use 18 && nvm alias default 18"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm não encontrado após instalação do Node.js."
        exit 1
    fi
    
    log_success "Node.js $(node --version) e npm $(npm --version) verificados com sucesso!"
}

# Criar estrutura de diretórios
create_structure() {
    log_info "Criando estrutura de diretórios..."
    
    if [ -d "chatflex" ]; then
        log_warning "Removendo diretório 'chatflex' existente para evitar conflitos..."
        rm -rf chatflex
        log_success "Diretório 'chatflex' removido!"
    fi
    
    mkdir -p chatflex/{backend,frontend,docker,docs}
    mkdir -p chatflex/backend/{src/{controllers,middleware,routes,services,utils},uploads,sessions}
    
    log_success "Estrutura de diretórios criada!"
}

# Configurar Backend
setup_backend() {
    log_info "Configurando Backend..."
    
    cd chatflex/backend
    
    cat > package.json << 'EOF_PACKAGE_JSON_BE'
{
  "name": "chatflex-backend",
  "version": "1.0.0",
  "description": "ChatFlex Backend - Sistema de Atendimento WhatsApp",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "build": "echo 'Backend build complete'",
    "test": "echo 'No tests specified'"
  },
  "keywords": ["whatsapp", "chatbot", "customer-service"],
  "author": "ChatFlex Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "@wppconnect-team/wppconnect": "^1.30.0",
    "socket.io": "^4.7.4",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "multer": "^1.4.5-lts.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "concurrently": "^8.2.2"
  }
}
EOF_PACKAGE_JSON_BE

    cat > .env << 'EOF_ENV_BE'
NODE_ENV=development
PORT=3001
JWT_SECRET=your-super-secret-jwt-key
WHATSAPP_SESSION=chatflex-session
UPLOAD_DIR=./uploads
SESSION_DIR=./sessions
EOF_ENV_BE

    cat > server.js << 'EOF_SERVER_JS'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middlewares
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir arquivos estáticos
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Rotas
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/whatsapp', require('./src/routes/whatsapp'));
app.use('/api/employees', require('./src/routes/employees'));
app.use('/api/conversations', require('./src/routes/conversations'));

// Rota de saúde
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
});
EOF_SERVER_JS

    cat > src/services/whatsappService.js << 'EOF_WAPP_SERVICE'
// src/services/whatsappService.js
const wppconnect = require('@wppconnect-team/wppconnect');

class WhatsAppService {
  constructor() {
    this.client = null;
    this.isConnected = false;
  }

  async initialize(session = 'chatflex-session') {
    try {
      this.client = await wppconnect.create({
        session: session,
        catchQR: (base64Qr, asciiQR) => {
          console.log('QR Code gerado:', asciiQR);
          // Emitir QR Code via Socket.IO
          this.onQRCode?.(base64Qr);
        },
        statusFind: (statusSession, session) => {
          console.log('Status da sessão:', statusSession, session);
          this.onStatusChange?.(statusSession);
        },
        headless: true,
        devtools: false,
        useChrome: false,
        debug: false,
        logQR: false,
        browserArgs: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-accelerated-2d-canvas',
          '--no-first-run',
          '--no-zygote',
          '--disable-gpu'
        ]
      });

      this.isConnected = true;
      console.log('✅ WhatsApp conectado com sucesso!');

      // Configurar listeners
      this.setupMessageListeners();

      return this.client;
    } catch (error) {
      console.error('❌ Erro ao conectar WhatsApp:', error);
      throw error;
    }
  }

  setupMessageListeners() {
    if (!this.client) return;

    this.client.onMessage((message) => {
      console.log('Nova mensagem recebida:', message);
      this.onMessage?.(message);
    });

    this.client.onAck((ack) => {
      console.log('Status da mensagem:', ack);
      this.onAck?.(ack);
    });
  }

  async sendMessage(to, message) {
    if (!this.client || !this.isConnected) {
      throw new Error('WhatsApp não conectado');
    }

    try {
      const result = await this.client.sendText(to, message);
      return result;
    } catch (error) {
      console.error('Erro ao enviar mensagem:', error);
      throw error;
    }
  }

  async sendFile(to, filePath, filename, caption) {
    if (!this.client || !this.isConnected) {
      throw new Error('WhatsApp não conectado');
    }

    try {
      const result = await this.client.sendFile(to, filePath, filename, caption);
      return result;
    } catch (error) {
      console.error('Erro ao enviar arquivo:', error);
      throw error;
    }
  }

  async getContacts() {
    if (!this.client || !this.isConnected) {
      throw new Error('WhatsApp não conectado');
    }

    try {
      const contacts = await this.client.getAllContacts();
      return contacts;
    } catch (error) {
      console.error('Erro ao buscar contatos:', error);
      throw error;
    }
  }

  async getChats() {
    if (!this.client || !this.isConnected) {
      throw new Error('WhatsApp não conectado');
    }

    try {
      const chats = await this.client.getAllChats();
      return chats;
    } catch (error) {
      console.error('Erro ao buscar conversas:', error);
      throw error;
    }
  }

  async disconnect() {
    if (this.client) {
      await this.client.close();
      this.isConnected = false;
      console.log('WhatsApp desconectado');
    }
  }
}

module.exports = new WhatsAppService();
EOF_WAPP_SERVICE

    mkdir -p src/routes
    
    cat > src/routes/auth.js << 'EOF_AUTH_JS'
const express = require('express');
const router = express.Router();

router.post('/login', (req, res) => {
  // Implementar lógica de login
  res.json({ message: 'Login endpoint' });
});

module.exports = router;
EOF_AUTH_JS

    cat > src/routes/whatsapp.js << 'EOF_WHATSAPP_JS'
const express = require('express');
const router = express.Router();

router.get('/status', (req, res) => {
  // Implementar status do WhatsApp
  res.json({ message: 'WhatsApp status endpoint' });
});

module.exports = router;
EOF_WHATSAPP_JS

    cat > src/routes/employees.js << 'EOF_EMPLOYEES_JS'
const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  // Implementar listagem de funcionários
  res.json({ message: 'Employees endpoint' });
});

module.exports = router;
EOF_EMPLOYEES_JS

    cat > src/routes/conversations.js << 'EOF_CONVERSATIONS_JS'
const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  // Implementar listagem de conversas
  res.json({ message: 'Conversations endpoint' });
});

module.exports = router;
EOF_CONVERSATIONS_JS

    cd ../..
    log_success "Backend configurado!"
}

# Configurar Frontend
setup_frontend() {
    log_info "Configurando Frontend..."
    
    cd chatflex/frontend
    
    log_warning "Limpando o diretório chatflex/frontend antes de criar o React App para evitar conflitos..."
    find . -mindepth 1 -delete 2>/dev/null || true 
    log_success "Conteúdo do diretório chatflex/frontend limpo!"
    
    npx create-react-app . --template minimal --silent
    
    npm install lucide-react tailwindcss postcss autoprefixer --silent
    
    npx tailwindcss init -p
    
    cat > tailwind.config.js << 'EOF_TAILWIND_CONFIG'
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF_TAILWIND_CONFIG

    cat > src/index.css << 'EOF_INDEX_CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    font-family: 'Inter', system-ui, -apple-system, sans-serif;
  }
}

@layer components {
  .custom-scrollbar {
    scrollbar-width: thin;
    scrollbar-color: #4B5563 #1F2937;
  }

  .custom-scrollbar::-webkit-scrollbar {
    width: 6px;
  }

  .custom-scrollbar::-webkit-scrollbar-track {
    background: #1F2937;
    border-radius: 3px;
  }

  .custom-scrollbar::-webkit-scrollbar-thumb {
    background: #4B5563;
    border-radius: 3px;
  }

  .custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background: #6B7280;
  }
}

@layer utilities {
  .animate-fade-in {
    animation: fadeIn 0.5s ease-in-out;
  }

  .animate-fade-in-down {
    animation: fadeInDown 0.3s ease-out;
  }
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
EOF_INDEX_CSS

    cat > src/App.js << 'EOF_APP_JS'
import React, { useState } from 'react';
import { MessageCircle, Users, Settings, Menu, X } from 'lucide-react';

function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('conversations');

  const menuItems = [
    { id: 'conversations', name: 'Conversas', icon: MessageCircle },
    { id: 'employees', name: 'Funcionários', icon: Users },
    { id: 'settings', name: 'Configurações', icon: Settings },
  ];

  return (
    <div className="flex h-screen bg-gray-100">
      {/* Sidebar */}
      <div className={`${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0`}>
        <div className="flex items-center justify-between h-16 px-4 border-b">
          <h1 className="text-xl font-bold text-gray-800">ChatFlex</h1>
          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden"
          >
            <X size={24} />
          </button>
        </div>
        <nav className="mt-4">
          {menuItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center px-4 py-3 text-left hover:bg-gray-50 ${
                activeTab === item.id ? 'bg-blue-50 text-blue-600 border-r-2 border-blue-600' : 'text-gray-700'
              }`}
            >
              <item.icon size={20} className="mr-3" />
              {item.name}
            </button>
          ))}
        </nav>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="bg-white shadow-sm border-b h-16 flex items-center justify-between px-4">
          <button
            onClick={() => setSidebarOpen(true)}
            className="lg:hidden"
          >
            <Menu size={24} />
          </button>
          <h2 className="text-lg font-semibold text-gray-800">
            {menuItems.find(item => item.id === activeTab)?.name}
          </h2>
          <div className="flex items-center space-x-4">
            <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
              <span className="text-white text-sm font-medium">A</span>
            </div>
          </div>
        </header>

        {/* Content */}
        <main className="flex-1 overflow-y-auto p-6">
          <div className="max-w-7xl mx-auto">
            {activeTab === 'conversations' && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Conversas do WhatsApp</h3>
                <p className="text-gray-600">Conecte seu WhatsApp para começar a gerenciar as conversas.</p>
                <button className="mt-4 bg-green-500 text-white px-4 py-2 rounded-lg hover:bg-green-600">
                  Conectar WhatsApp
                </button>
              </div>
            )}
            
            {activeTab === 'employees' && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Gerenciar Funcionários</h3>
                <p className="text-gray-600">Adicione e gerencie os funcionários que terão acesso ao sistema.</p>
              </div>
            )}
            
            {activeTab === 'settings' && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Configurações</h3>
                <p className="text-gray-600">Configure as opções do sistema.</p>
              </div>
            )}
          </div>
        </main>
      </div>

      {/* Overlay para mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        ></div>
      )}
    </div>
  );
}

export default App;
EOF_APP_JS

    cd ../..
    log_success "Frontend configurado!"
}

# Configurar Docker
setup_docker() {
    log_info "Configurando Docker..."
    
    cat > chatflex/backend/Dockerfile << 'EOF_DOCKERFILE_BE'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3001

CMD ["npm", "start"]
EOF_DOCKERFILE_BE

    cat > chatflex/frontend/Dockerfile << 'EOF_DOCKERFILE_FE'
FROM node:18-alpine as build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF_DOCKERFILE_FE

    cat > chatflex/frontend/nginx.conf << 'EOF_NGINX_CONF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://backend:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF_NGINX_CONF

    cat > chatflex/docker-compose.yml << 'EOF_DOCKER_COMPOSE'
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "3001:3001"
    volumes:
      - ./backend/sessions:/app/sessions
      - ./backend/uploads:/app/uploads
    environment:
      - NODE_ENV=production
      - JWT_SECRET=your-jwt-secret-here
    restart: unless-stopped

  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    depends_on:
      - backend
    restart: unless-stopped

volumes:
  sessions:
  uploads:
EOF_DOCKER_COMPOSE

    cat > chatflex/docker-compose.casaos.yml << 'EOF_DOCKER_COMPOSE_CASAOS'
name: chatflex

services:
  app:
    image: chatflex:latest
    container_name: chatflex
    ports:
      - "3000:3000"
      - "3001:3001"
    volumes:
      - /DATA/AppData/chatflex/sessions:/app/backend/sessions
      - /DATA/AppData/chatflex/uploads:/app/backend/uploads
      - /DATA/AppData/chatflex/config:/app/config
    environment:
      - NODE_ENV=production
      - JWT_SECRET=chatflex-secret-key
    restart: unless-stopped
    x-casaos:
      architectures:
        - amd64
        - arm64
      main: app
      description:
        en_us: "ChatFlex - Sistema de Atendimento WhatsApp completo"
      tagline:
        en_us: WhatsApp Customer Service System
      developer: "ChatFlex Team"
      author: ChatFlex
      icon: https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/whatsapp.png
      thumbnail: https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/whatsapp.png
      title:
        en_us: ChatFlex
      category: Communication
      port_map: "3000"
EOF_DOCKER_COMPOSE_CASAOS

    log_success "Docker configurado!"
}

# Criar documentação
create_docs() {
    log_info "Criando documentação..."
    
    cat > chatflex/README.md << 'EOF_README_MD'
# ChatFlex - Sistema de Atendimento WhatsApp

## 📋 Pré-requisitos

- Node.js (versão 18 ou superior)
- npm ou yarn
- Docker (opcional, para containerização)
- CasaOS (opcional, para instalação via interface gráfica)

## 🚀 Instalação

### Desenvolvimento

1. **Backend:**
```bash
cd backend
npm install
npm run dev
