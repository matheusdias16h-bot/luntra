# Lutra

Catálogo de cursos e painel de gerenciamento em português, com frontend estático, Supabase Auth/Postgres e deploy estático.

## Stack

- HTML, CSS e JavaScript sem framework no cliente.
- Supabase Auth e Postgres com Row Level Security.
- Render Static Sites ou Netlify para build/deploy estático.
- PWA com manifesto e cache offline da estrutura pública.

## Rodar localmente

Requer Node.js 20 ou superior.

```sh
npm run dev
```

Acesse `http://localhost:4173`. Sem Supabase configurado, o catálogo mostra cursos fictícios marcados como demonstração; não há links externos ativos nesses registros.

## Supabase

1. Projeto Lutra: `dirufihqwzgyqcythsdb` (região `sa-east-1`). O esquema inicial já está aplicado.
2. O cadastro público em `/cadastro` cria usuários comuns no Supabase Auth. Nome e telefone são salvos como metadados do usuário; senhas são gerenciadas pelo Auth e nunca gravadas em tabelas da aplicação.
4. Para criar um administrador, copie o UUID do usuário em Authentication > Users e execute o comando comentado no final de `schema.sql`. Cadastros públicos nunca recebem acesso administrativo.
5. Para desenvolvimento local, copie `.env.example` para `.env`; `npm run dev` carrega essas variáveis. `.env` está ignorado pelo Git.
6. Configure `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SITE_URL` como variáveis de build no serviço de publicação. Use apenas a chave publicável/anon no frontend. Nunca use `service_role` ou secret key no navegador.
7. Em Authentication > URL Configuration, cadastre o domínio local e o domínio final publicado como URLs permitidas para redirecionamento de confirmação de e-mail.

RLS restringe gravação e leitura administrativa aos UUIDs cadastrados em `admin_users`. A coluna `affiliate_url` não é concedida à função `anon`; o RPC `track_course_click` registra os dados mínimos e retorna o URL somente para o redirecionamento solicitado.

## Build e deploy

```sh
npm run build
```

O resultado fica em `dist/`. Para Render Static Sites, use `npm run build` como Build Command e `dist` como Publish Directory. Defina `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SITE_URL` nas variáveis de ambiente/build do serviço. Cadastre o domínio final também nas URLs permitidas do Supabase Auth.

Para publicar pelo GitHub, conecte uma cópia deste diretório ao repositório `https://github.com/matheusdias16h-bot/luntra`. O ambiente Codex atual não possui credenciais GitHub disponíveis.

## Administração

Acesse `/painel-secreto/login` e entre com o usuário criado no Supabase e promovido em `admin_users`. Não existe link administrativo na navegação pública, e as políticas RLS protegem dados independentemente de o caminho ser conhecido. Cursos demonstrativos não podem ser comprados; cadastre cursos reais com URLs completas HTTP(S).

## Marca e PWA

O nome da aplicação fica em `app.js` (`defaults`), com metadados de instalação em `manifest.webmanifest`. As cores principais ficam centralizadas nas variáveis CSS no começo de `styles.css` e `brand-overrides.css`. `static/img/logo.png` guarda a arte original e `static/img/mascote.png` é o recorte usado na interface. O service worker mantém arquivos estáticos disponíveis offline; catálogo, autenticação e redirecionamentos precisam de rede.

## Limites atuais

O painel implementa autenticação, dashboard básico, listagem e CRUD de cursos (criação, edição, ativação/desativação). Os dados demonstrativos são locais e não simulam gravações. O cadastro de categorias e plataformas deve ser feito inicialmente pelo SQL Editor ou dashboard Supabase. O contador de cliques está disponível, com relatórios detalhados e upload seguro de imagens planejados para uma etapa posterior. Páginas de curso são renderizadas no cliente; para indexação dinâmica avançada por curso, recomenda-se migrar o frontend para renderização server-side/estática por rota.
