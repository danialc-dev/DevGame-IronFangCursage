local anim = require 'anim8'

-- ativar/desativar o DEBUG
local debugMode = false  -- Mude para false para desativar

-- Variáveis para o game OVER
local deathSound -- Variável para o som de morte
local deathSoundFade = 0
local gameOverBackground

-- Variáveis para o menu
local menuState = true
local backgroundMenu
local musicMenu
local font
local buttons = {
    start = {x = 0, y = 0, width = 200, height = 50, text = "Iniciar Jogo"},
    exit = {x = 0, y = 0, width = 200, height = 50, text = "Sair"}
}

local italicFont = love.graphics.newFont("insumos/Fontes/Roboto-Italic.ttf", 14)

--sounds
local coinSound
love.audio.setVolume(0.2)

-- Variavrel lobo
local LobosController = {}

-- Estados do jogo
local gameStates = {
    MENU = 1,
    PLAYING = 2,
    GAME_OVER = 3
}
local currentGameState = gameStates.MENU

-- Botões do Game Over
local gameOverButtons = {
    restart = {x = 0, y = 0, width = 200, height = 50, text = "Reiniciar"},
    menu = {x = 0, y = 0, width = 200, height = 50, text = "Voltar ao Menu"}
}

-- Classe base para objetos do jogo
local GameObject = {}
function GameObject:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- classe para criar a particula e suas caracteristicas
-- Adicione isso no início do arquivo, junto com as outras declarações
local Coin = GameObject:new()
function Coin:new(o)
    o = o or {
        x = 0,
        y = 0,
        value = 10, -- Valor em pontos
        collected = false,
        animation = nil,
        image = nil,
        active = true,
        canBeCollected = false,  
        spawnTime = 0,         
        collectDelay = 0.5
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Coin:load()
    self.image = love.graphics.newImage("insumos/Sprite_Particula/Particula2.png")
    local grid = anim.newGrid(35, 40, self.image:getWidth(), self.image:getHeight())
    local frames = math.floor(self.image:getWidth() / 36)
    self.animation = anim.newAnimation(grid('1-'..frames, 1), 0.2)
end

function Coin:update(dt)
    if not self.collected and self.active then
        self.spawnTime = self.spawnTime + dt
        
        -- Habilita a coleta após o delay
        if self.spawnTime >= self.collectDelay then
            self.canBeCollected = true
        end
        
        self.animation:update(dt)
    end
end

function Coin:draw(cameraX)
    if not self.collected and self.active then
        -- Efeito de fade-in (opcional)
        local alpha = math.min(1, self.spawnTime / self.collectDelay)  -- Vai de 0 a 1
        love.graphics.setColor(1, 1, 1, alpha)  -- Aplica transparência
        
        -- Desenha a moeda
        local drawY = self.y - 18 + 10  -- Ajuste de posição (como antes)
        self.animation:draw(self.image, self.x - cameraX - 18, drawY, 0, 1.3, 1.3)
        
        -- Reseta cor para evitar afetar outros elementos
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Debug (se necessário)
        if debugMode then
            love.graphics.setColor(1, 1, 0, 0.5 * alpha)  -- Hitbox semi-transparente
            love.graphics.rectangle("line", self.x - cameraX - 18, drawY, 54, 54)
            love.graphics.setColor(1, 1, 1)
        end
    end
end


-- Classe do Personagem
local Personagem = GameObject:new()
function Personagem:new(o)
    o = o or {
        posX = 100,
        posY = 146,
        direcao = true,
        estado = "andar",
        emChao = true,
        puloVelocidade = -350,
        gravidade = 800,
        vida = 100,
        podeTomarDano = true,
        tempoInvulnerabilidade = 1,
        tempoDano = 0,
        morreu = false,
        velocidade = 140,
        defendendo = false,
        tempoDefesa = 0,     
        duracaoDefesa = 0.5,
        loboDanoCooldown = false,
        tempoLoboDanoCooldown = 0,
        deathAnimationComplete = false,
        danoAplicado = false,  -- Flag para controlar se o dano já foi aplicado nesse frame
        power = 0,
        maxPower = 100,
    }
    self.__index = self
    return setmetatable(o, self)
end

--função para receber o poder dado pelas coins
function Personagem:addPower(amount)
    self.power = math.min(self.power + amount, self.maxPower)
    if coinSound then
        coinSound:stop()
        coinSound:play()
    end
    if self.power >= self.maxPower then
        -- Aqui você pode adicionar lógica para quando o poder estiver cheio
        print("Poder máximo alcançado! Pronto para enfrentar o BOSS!")
    end
end

function Personagem:load()
    self.imagemEstatico = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Idle.png")
    local estatico = anim.newGrid(127, 128, self.imagemEstatico:getWidth(), self.imagemEstatico:getHeight())
    self.animacaoEstatico = anim.newAnimation(estatico('1-'..math.floor(self.imagemEstatico:getWidth() / 127), 1), 0.13)

    self.imagemAndar = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Walk.png")
    local walk = anim.newGrid(127, 128, self.imagemAndar:getWidth(), self.imagemAndar:getHeight())
    self.animacaoAndar = anim.newAnimation(walk('1-5', 1), 0.13)

    self.imagemCorrer = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Run.png")
    local run = anim.newGrid(127, 128, self.imagemCorrer:getWidth(), self.imagemCorrer:getHeight())
    self.animacaoCorrer = anim.newAnimation(run('1-'..math.floor(self.imagemCorrer:getWidth() / 127), 1), 0.09)

    self.imagemPular = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Jump.png")
    local jump = anim.newGrid(127, 128, self.imagemPular:getWidth(), self.imagemPular:getHeight())
    self.animacaoPular = anim.newAnimation(jump('1-'..math.floor(self.imagemPular:getWidth() / 127), 1), 0.1)

    self.imagemDefender = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Protect.png")
    local defend = anim.newGrid(128, 128, self.imagemDefender:getWidth(), self.imagemDefender:getHeight())
    self.animacaoDefender = anim.newAnimation(defend('1-'..math.floor(self.imagemDefender:getWidth() / 128), 1), 0.1)

    self.imagemAtaque1 = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Attack3.png")
    local ataque1 = anim.newGrid(127, 128, self.imagemAtaque1:getWidth(), self.imagemAtaque1:getHeight())
    self.animacaoAtaque1 = anim.newAnimation(ataque1('1-'..math.floor(self.imagemAtaque1:getWidth() / 127), 1), 0.12)

    self.imagemAtaque2 = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Attack1.png")
    local ataque2 = anim.newGrid(128, 128, self.imagemAtaque2:getWidth(), self.imagemAtaque2:getHeight())
    self.animacaoAtaque2 = anim.newAnimation(ataque2('1-'..math.floor(self.imagemAtaque2:getWidth() / 127), 1), 0.20)

    self.imagemMorte = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Dead.png")
    local morte = anim.newGrid(128, 128, self.imagemMorte:getWidth(), self.imagemMorte:getHeight())
    self.animacaoMorte = anim.newAnimation(morte('1-'..math.floor(self.imagemMorte:getWidth() / 128), 1), 0.14)

    self.imagemDano = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Hurt.png")
    local dano = anim.newGrid(128, 128, self.imagemDano:getWidth(), self.imagemDano:getHeight())
    self.animacaoDano = anim.newAnimation(dano('1-'..math.floor(self.imagemDano:getWidth() / 128), 1), 0.22)
end

function Personagem:estaAtacando()
    return self.estado == "atacar" or self.estado == "atacar2"
end

function Personagem:frameDeDano()
    if self.estado == "atacar" then
        print("Frame de ataque normal: "..self.animacaoAtaque1.position)
        return self.animacaoAtaque1.position >= 3 and self.animacaoAtaque1.position <= 5
    elseif self.estado == "atacar2" then
        print("Frame de ataque forte: "..self.animacaoAtaque2.position)
        return self.animacaoAtaque2.position >= 2 and self.animacaoAtaque2.position <= 4
    end
    return false
end

function Personagem:colisaoComLobo()
    local lobosAtivos = self.lobosController:getLobosAtivos()  -- Note a mudança aqui
    
    for _, lobo in ipairs(lobosAtivos) do
        -- Hitbox do ataque
        local ataqueLargura = 100
        local ataqueAltura = 60
        local ataqueOffsetX = self.direcao and 70 or -30
        local ataqueX = self.posX + ataqueOffsetX
        local ataqueY = self.posY + 180
        
        -- Hitbox do lobo (ajustada)
        local loboLargura = 70
        local loboAltura = 50
        local loboX = lobo.x
        local loboY = lobo.y - 10
        
        -- Verificação de colisão
        if ataqueX < loboX + loboLargura and
           ataqueX + ataqueLargura > loboX and
           ataqueY < loboY + loboAltura and
           ataqueY + ataqueAltura > loboY then
            return lobo
        end
    end
    return nil
end

function Personagem:update(dt)
    -- Atualiza o tempo de defesa
    if self.defendendo then
        self.tempoDefesa = self.tempoDefesa + dt
        if self.tempoDefesa >= self.duracaoDefesa then
            self:pararDefesa()
        end
    end

    -- Atualiza o tempo de invulnerabilidade após o dano
    if not self.podeTomarDano then
        self.tempoDano = self.tempoDano - dt
        if self.tempoDano <= 0 then
            self.podeTomarDano = true
            if self.estado == "dano" then
                self.estado = "estatico"
            end
        end
    end

    -- Verificação de morte
    if self.vida <= 0 and not self.morreu then
        self.morreu = true
        self.estado = "morte"
        self.animacaoMorte:gotoFrame(1)
        love.audio.play(deathSound)
        self.deathAnimationComplete = false
    end

    -- Se estiver morto, apenas atualiza a animação
    if self.morreu then
        if not self.deathAnimationComplete then
            self.animacaoMorte:update(dt)
            if self.animacaoMorte.position == #self.animacaoMorte.frames then
                self.deathAnimationComplete = true
            end
        end
        return
    end

    -- Pulo
    if love.keyboard.isDown('space') and self.emChao and self.estado ~= "morte" then
        self.estado = "pular"
        self.emChao = false
        self.puloVelocidade = -350
    end

    -- Gravidade e movimento no ar
    if not self.emChao then
        self.posY = self.posY + self.puloVelocidade * dt
        self.puloVelocidade = self.puloVelocidade + self.gravidade * dt
        if self.posY >= 146 then
            self.posY = 146
            self.emChao = true
            self.puloVelocidade = -230
            if self.estado == "pular" then
                self.estado = "estatico"
            end
        end
    end

    -- Controle de estados (ataque, defesa, movimento)
    if self.defendendo then
        self.estado = "defender"
    elseif self.estado ~= "dano" and self.estado ~= "morte" and self.estado ~= "pular" then
        -- Defesa com botão direito do mouse
        if love.mouse.isDown(2) and not self.defendendo and self.estado ~= "atacar" and self.estado ~= "atacar2" then
            self:iniciarDefesa()
        end

        -- Ataque com botão esquerdo do mouse
        if love.mouse.isDown(1) and self.estado ~= "atacar" and self.estado ~= "atacar2" then
            self.estado = "atacar"
            self.animacaoAtaque1:gotoFrame(1)
            self.danoAplicado = false  -- Reset do flag de dano
        end

        -- Movimento normal (andar/correr)
        if not self:estaAtacando() and not self.defendendo then
            if love.keyboard.isDown('a') or love.keyboard.isDown('d') then
                if love.keyboard.isDown("lshift") then
                    self.estado = "correr"
                    self.velocidade = 200
                else
                    self.estado = "andar"
                    self.velocidade = 140
                end
                self.direcao = not love.keyboard.isDown("a")
            else
                self.estado = "estatico"
            end
        end
    end

    -- SISTEMA DE DANO CONTRA LOBOS (PARTE CRÍTICA)
    if self:estaAtacando() and self:frameDeDano() and not self.danoAplicado then
        local lobo = self:colisaoComLobo()
        if lobo and lobo.podeTomarDano then
            local dano = (self.estado == "atacar") and 20 or 40  -- Dano diferente por tipo de ataque
            lobo:tomarDano(dano)
            self.danoAplicado = true  -- Evita múltiplos hits em um único ataque
            if debugMode then
                print(string.format("Dano aplicado: %d (Vida do lobo: %d)", dano, lobo.vida))
            end
        end
    elseif not self:estaAtacando() then
        self.danoAplicado = false  -- Reset do flag quando o ataque termina
    end

    -- Movimento horizontal (se não estiver tomando dano ou morto)
    if self.estado ~= "dano" and self.estado ~= "morte" and not self:estaAtacando() and not self.defendendo then
        if love.keyboard.isDown("a") then
            self.posX = self.posX - self.velocidade * dt
        elseif love.keyboard.isDown("d") then
            self.posX = self.posX + self.velocidade * dt
        end
    end

    -- Atualização das animações (sem alterações)
    if self.estado == "dano" then
        self.animacaoDano:update(dt)
    elseif self.estado == "morte" then
        self.animacaoMorte:update(dt)
    elseif self.estado == "estatico" then
        self.animacaoEstatico:update(dt)
    elseif self.estado == "defender" then
        self.animacaoDefender:update(dt)
    elseif self.estado == "atacar" then
        self.animacaoAtaque1:update(dt)
        if self.animacaoAtaque1.position == #self.animacaoAtaque1.frames then
            self.estado = "estatico"
        end
    elseif self.estado == "atacar2" then
        self.animacaoAtaque2:update(dt)
        if self.animacaoAtaque2.status == "finished" then
            self.estado = "estatico"
            self.animacaoAtaque2:gotoFrame(1) -- reset para o próximo uso
        end
    elseif not self.emChao then
        self.animacaoPular:update(dt)
    elseif self.estado == "andar" then
        self.animacaoAndar:update(dt)
    elseif self.estado == "correr" then
        self.animacaoCorrer:update(dt)
    end
end

function Personagem:iniciarDefesa()
    self.defendendo = true
    self.tempoDefesa = 0
    self.estado = "defender"
    self.animacaoDefender:gotoFrame(1)
    self.podeTomarDano = false
end

function Personagem:pararDefesa()
    self.defendendo = false
    self.estado = "estatico"
    self.podeTomarDano = true
end

function Personagem:draw(cameraX)
    local animacao, imagem

    if self.morreu then
        local escalaX = self.direcao and 2 or -2
        self.animacaoMorte:draw(self.imagemMorte, self.posX - cameraX, self.posY, 0, escalaX, 2, 48, 0)
        return
    end

    if self.estado == "dano" then
        animacao = self.animacaoDano
        imagem = self.imagemDano
    elseif self.estado == "morte" then
        animacao = self.animacaoMorte
        imagem = self.imagemMorte
    elseif self.estado == "defender" then
        animacao = self.animacaoDefender
        imagem = self.imagemDefender
    elseif self.estado == "estatico" then
        animacao = self.animacaoEstatico
        imagem = self.imagemEstatico
    elseif self.estado == "atacar" then
        animacao = self.animacaoAtaque1
        imagem = self.imagemAtaque1
    elseif self.estado == "atacar2" then
        animacao = self.animacaoAtaque2
        imagem = self.imagemAtaque2
    elseif not self.emChao then
        animacao = self.animacaoPular
        imagem = self.imagemPular
    elseif self.estado == "andar" then
        animacao = self.animacaoAndar
        imagem = self.imagemAndar
    elseif self.estado == "correr" then
        animacao = self.animacaoCorrer
        imagem = self.imagemCorrer
    end

    local escalaX = self.direcao and 2 or -2
    animacao:draw(imagem, self.posX - cameraX, self.posY, 0, escalaX, 2, 48, 0)
end

-- Classe do Lobo
local Lobo = GameObject:new()
function Lobo:new(o)
    o = o or {
        x = 200,
        y = 335,
        direcao = false,
        estado = "correr",
        tempoAtaque = 0,
        cooldownAtaque = 1,
        vida = 80,
        spawnado = false,
        tempoHurt = 0,
        podeTomarDano = true,
        ativo = false,
        tempoMorte = 0,
        tempoParaDesaparecer = 1.5,
        velocidade = 120, -- Adiciona velocidade base
    }
    self.__index = self
    return setmetatable(o, self)
end

-- Sistema de controle de lobos
function LobosController:new()
    local o = {
        lobos = {},
        coins = {},
        tempoEntreSpawns = 6,
        tempoUltimoSpawn = 0,
        maxLobosAtivos = 3,
        lobosParaSpawnar = {},
        ondaAtual = 1,  -- Adiciona esta linha para controlar a onda atual
        tempoEntreOndas = 10  -- Tempo entre ondas em segundos
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--spawn de coins
function LobosController:spawnCoin(x, y)
    local newCoin = Coin:new()
    newCoin:load()
    newCoin.x = x
    newCoin.y = y - 17 -- Ajuste para aparecer um pouco acima do lobo
    table.insert(self.coins, newCoin)
    return newCoin
end

--chegar colisao com as coins
local function checkCollision(obj1, obj2)
    -- Ajuste para os tamanhos reais (considerando a escala 1.5 da moeda)
    local obj1Width, obj1Height = 50, 160 
    local obj2Width, obj2Height = 54, 54   
    
    -- Ajuste das posições considerando o offset
    local coinX = obj2.x - 18  
    local coinY = obj2.y - 18
    
    return obj1.posX < coinX + obj2Width and
           obj1.posX + obj1Width > coinX and
           obj1.posY < coinY + obj2Height and
           obj1.posY + obj1Height > coinY
end

-- Adicione estas funções ao LobosController (logo após a definição):
function LobosController:init()
    self.lobos = {}
    self.tempoUltimoSpawn = 0
    self.ondaAtual = 1  -- Reinicia a onda
    self:gerarOndaLobos()  -- Remove o parâmetro
end

function LobosController:gerarOndaLobos(onda)
    self.lobosParaSpawnar = {}
    local quantidade = 3 + self.ondaAtual -- Aumenta a quantidade por onda
    
    for i = 1, quantidade do
        table.insert(self.lobosParaSpawnar, {
            tempo = (i-1) * 2, -- Spawna a cada 2 segundos
            spawnado = false
        })
    end
end

function LobosController:update(dt, personagem)
    -- Atualiza o tempo desde o último spawn
    self.tempoUltimoSpawn = self.tempoUltimoSpawn + dt
    
    -- Conta lobos ativos (vivos)
    local lobosAtivos = 0
    for _, lobo in ipairs(self.lobos) do
        if lobo.ativo and lobo.estado ~= "morte" then
            lobosAtivos = lobosAtivos + 1
        end
    end

    print("Lobos ativos:", #self.lobos, "Moedas ativas:", #self.coins)  -- DEBUG
    
    -- Verifica se pode spawnar um novo lobo
    if self.tempoUltimoSpawn >= self.tempoEntreSpawns and lobosAtivos < self.maxLobosAtivos then
        self:spawnLobo(personagem)
        self.tempoUltimoSpawn = 0 -- Reinicia o contador
    end
    
    -- Atualiza e remove lobos mortos
    for i = #self.lobos, 1, -1 do
        local lobo = self.lobos[i]
        
        if lobo.ativo then
            -- Atualiza o lobo
            lobo:update(dt, personagem)
            
            -- Remove se saiu da tela ou morreu
            if lobo.x < (personagem.posX - love.graphics.getWidth() * 1.5) or 
            (lobo.estado == "morte" and lobo.tempoMorte >= lobo.tempoParaDesaparecer) then
             table.remove(self.lobos, i)
            end
        end
    end

    -- Atualiza e remove moedas coletadas
        -- Atualiza e remove moedas coletadas
        for i = #self.coins, 1, -1 do
            local coin = self.coins[i]
            if coin.active and not coin.collected then
                coin:update(dt)
                
                -- Verifica colisão com o personagem
                if checkCollision(personagem, coin) and coin.canBeCollected then  -- Só coleta se canBeCollected == true
                    coin.collected = true
                    personagem:addPower(coin.value)
                    table.remove(self.coins, i)
                end
            end
        end
    end
    



function LobosController:spawnLobo(personagem)
    local novoLobo = Lobo:new()
    novoLobo:load()
    
    -- Aumenta stats conforme as ondas avançam
    novoLobo.vida = 80 + (self.ondaAtual * 10)
    novoLobo.velocidade = 120 + (self.ondaAtual * 5)
    
    -- Posição de spawn
    novoLobo.x = personagem.posX + love.graphics.getWidth() + 50
    novoLobo.y = 335
    novoLobo.ativo = true
    novoLobo.lobosController = self
    
    table.insert(self.lobos, novoLobo)
    return novoLobo
end

function LobosController:verificarFimDeOnda()
    if #self.lobos == 0 and #self.lobosParaSpawnar == 0 then
        self.ondaAtual = self.ondaAtual + 1
        self:gerarOndaLobos(self.ondaAtual)
        return true
    end
    return false
end

function LobosController:draw(cameraX)
    for _, lobo in ipairs(self.lobos) do
        if lobo.ativo then
            lobo:draw(cameraX)
        end
    end

    -- Desenha moedas
    for _, coin in ipairs(self.coins) do
        coin:draw(cameraX)
    end
end

function LobosController:getLobosAtivos()
    local ativos = {}
    for _, lobo in ipairs(self.lobos) do
        if lobo.ativo and lobo.estado ~= "morte" then
            table.insert(ativos, lobo)
        end
    end
    return ativos
end

function Lobo:load()
    self.imagemEstatico = love.graphics.newImage("insumos/Sprite_Wolf/iddle.png")
    local estatico = anim.newGrid(65, 41, self.imagemEstatico:getWidth(), self.imagemEstatico:getHeight())
    self.animacaoEstatico = anim.newAnimation(estatico('1-'..math.floor(self.imagemEstatico:getWidth() / 96), 1), 0.18)

    self.imagemRun = love.graphics.newImage("insumos/Sprite_Wolf/walk.png") 
    local run = anim.newGrid(66, 31, self.imagemRun:getWidth(), self.imagemRun:getHeight())
    self.animacaoRun = anim.newAnimation(run('1-'..math.floor(self.imagemRun:getWidth() / 96), 1), 0.18)

    self.imagemAtaque = love.graphics.newImage("insumos/Sprite_Wolf/attack.png")
    local ataque = anim.newGrid(64, 32, self.imagemAtaque:getWidth(), self.imagemAtaque:getHeight())
    self.animacaoAtaque = anim.newAnimation(ataque('1-'..math.floor(self.imagemAtaque:getWidth() / 96), 1), 0.22)

    self.imagemHurt = love.graphics.newImage("insumos/Sprite_Wolf/hurt.png")
    local hurt = anim.newGrid(64, 41, self.imagemHurt:getWidth(), self.imagemHurt:getHeight())
    self.animacaoHurt = anim.newAnimation(hurt('1-'..math.floor(self.imagemHurt:getWidth() / 64), 1), 0.15)

    self.imagemDeath = love.graphics.newImage("insumos/Sprite_Wolf/death.png")
    local death = anim.newGrid(65, 32, self.imagemDeath:getWidth(), self.imagemDeath:getHeight())
    self.animacaoDeath = anim.newAnimation(death('1-'..math.floor(self.imagemDeath:getWidth() / 96), 1), 0.14)
end

function Lobo:tomarDano(dano)
    if not self.podeTomarDano or self.estado == "morte" then 
        return 
    end
    
    self.vida = math.max(0, self.vida - dano)
    
    if self.vida <= 0 then
        self.estado = "morte"
        self.tempoMorte = 0
        self.animacaoDeath:gotoFrame(1)
        print("Lobo derrotado!")

        -- Spawna uma moeda quando o lobo morre
        if self.lobosController then
            self.lobosController:spawnCoin(self.x, self.y)
        end
    else
        self.estado = "hurt"
        self.animacaoHurt:gotoFrame(1)
        self.tempoHurt = 0.5
        self.podeTomarDano = false
    end

    if self.vida <= 0 then
        print("Lobo morrendo, tentando criar moeda...")
        if self.lobosController then
            print("Controlador encontrado, criando moeda em:", self.x, self.y)
            self.lobosController:spawnCoin(self.x, self.y)
        else
            print("ERRO: Controlador de lobos não encontrado!")
        end
    end
end

function Lobo:update(dt, personagem)
    if self.estado == "morte" then
        self.tempoMorte = self.tempoMorte + dt
        self.animacaoDeath:update(dt)
        return
    end

    -- Estado hurt (quando leva dano)
    if self.estado == "hurt" then
        self.tempoHurt = self.tempoHurt - dt
        if self.tempoHurt <= 0 then
            self.estado = "correr"
            self.podeTomarDano = true
        end
        return
    end

    -- Movimento em direção ao personagem
    local distancia = math.abs(self.x - personagem.posX)
    
    if distancia > 60 then
        -- Persegue o personagem
        self.x = self.x - self.velocidade * dt
        self.estado = "correr"
        self.direcao = false
    else
        -- Ataque quando está perto
        self.estado = "atacar"
        
        -- Verifica frame de ataque
        if self.animacaoAtaque.position == 3 and not self.danoAplicado then
            self.danoAplicado = true
            
            -- Aplica dano se o personagem não estiver defendendo
            if personagem.podeTomarDano and not personagem.defendendo then
                personagem.vida = personagem.vida - 15
                personagem.podeTomarDano = false
                personagem.tempoDano = personagem.tempoInvulnerabilidade
                personagem.estado = "dano"
            end
        elseif self.animacaoAtaque.position ~= 3 then
            self.danoAplicado = false
        end
    end
    
    -- Atualiza animação
    if self.estado == "correr" then
        self.animacaoRun:update(dt)
    elseif self.estado == "atacar" then
        self.animacaoAtaque:update(dt)
    end
end

function Lobo:draw(cameraX)
    if not self.ativo then return end
    
    local escalaX = self.direcao and 2 or -2
    local offsetX = 30
    local offsetY = 0
    
    if self.estado == "hurt" then
        offsetY = -14  -- Ajuste este valor conforme necessário
    end

    -- Desenha a animação apropriada
    if self.estado == "morte" then
        self.animacaoDeath:draw(self.imagemDeath, self.x - cameraX + offsetX, self.y + offsetY, 0, escalaX, 2, 32, 0)
    elseif self.estado == "hurt" then
        self.animacaoHurt:draw(self.imagemHurt, self.x - cameraX + offsetX, self.y + offsetY, 0, escalaX, 2, 32, 0)
    elseif self.estado == "atacar" then
        self.animacaoAtaque:draw(self.imagemAtaque, self.x - cameraX + offsetX, self.y + offsetY, 0, escalaX, 2, 32, 0)
    else
        self.animacaoRun:draw(self.imagemRun, self.x - cameraX + offsetX, self.y + offsetY, 0, escalaX, 2, 32, 0)
    end

    -- Barra de vida (só se não estiver morto)
    if self.estado ~= "morte" then
        local barraVidaX = self.x - cameraX - 20
        local barraVidaY = self.y - 25
        local barraVidaLargura = self.vida / 80 * 50

        love.graphics.setColor(1, 0, 0) 
        love.graphics.rectangle("fill", barraVidaX, barraVidaY, barraVidaLargura, 6)
        love.graphics.setColor(1, 1, 1)
    end
end


-- Classe do Jogo
local Jogo = {}
function Jogo:new()
    local o = {
        background = nil,
        larguraBg = 0,
        cameraX = 0,
        personagem = Personagem:new(),
        lobosController = LobosController:new()
    }
    o.personagem.lobosController = o.lobosController
    setmetatable(o, self)
    self.__index = self
    o.lobosController:init()  -- Inicializa o controlador de lobos
    return o
end

function Jogo:load()
    self.background = love.graphics.newImage("insumos/Background/background.png")
    self.larguraBg = self.background:getWidth()
    self.personagem:load()
    
    -- Certifique-se de que o controlador de lobos é inicializado corretamente
    if not self.lobosController then
        self.lobosController = LobosController:new()
    end
    self.lobosController:init()
end

function Jogo:update(dt)
    self.personagem:update(dt)
    self.lobosController:update(dt, self.personagem)
    self.cameraX = self.personagem.posX - love.graphics.getWidth() / 2
end

function Jogo:draw()
    -- Desenha o background
    local startX = -(self.cameraX % self.larguraBg)
    for i = -1, 2 do
        love.graphics.draw(self.background, startX + i * self.larguraBg, 0)
    end

    -- Desenha os lobos e moedas
    self.lobosController:draw(self.cameraX)
    
    -- Desenha o personagem
    self.personagem:draw(self.cameraX)

    if debugMode then
        self:drawDebug()
    end
    
    -- Debug: Verifica valores
    print("Power:", self.personagem.power, "/", self.personagem.maxPower) -- Adicione esta linha
    
  
    --fundo das barras de vida e poder
    love.graphics.setFont(italicFont)

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.rectangle("fill", 7, 5, self.personagem.vida * 2.2, 86)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Life", 13, 7)

    -- Barra de vida (verde)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 10, 25, self.personagem.vida * 2, 25)
    love.graphics.setColor(0, 1, 0) 
    love.graphics.rectangle("fill", 10, 25, self.personagem.vida * 2, 25)

    -- escrito da barra de poder
    love.graphics.setColor(0, 0, 0) 
    love.graphics.print("Power", 10, 50)

    -- Barra de poder (azul)
    love.graphics.setColor(0, 0, 0) 
    love.graphics.rectangle("fill", 10, 65, self.personagem.maxPower * 2, 20)
    love.graphics.setColor(0, 0.67, 1, 1)
    love.graphics.rectangle("fill", 10, 65, self.personagem.power * 2, 20)
    
    love.graphics.setColor(1, 1, 1) 

    -- Debug info
    love.graphics.print("Estado: " .. self.personagem.estado, 10, 70)
    love.graphics.print("Lobos: " .. #self.lobosController:getLobosAtivos(), 10, 90)
    love.graphics.print("Spawn: " .. math.floor(self.lobosController.tempoEntreSpawns - self.lobosController.tempoUltimoSpawn) .. "s", 10, 110)
    love.graphics.print("Power: " .. self.personagem.power .. "/" .. self.personagem.maxPower, 10, 130)
end

-- Funções para o menu
function loadMenu()
    backgroundMenu = love.graphics.newImage("insumos/BackgroundMenu/menu2.png") 
    musicMenu = love.audio.newSource("insumos/SondsTrack/menuMusic.mp3", "stream")
    musicMenu:setLooping(true)
    musicMenu:play()

    gameOverBackground = love.graphics.newImage("insumos/BackgroundMenu/gameOver.png")

    deathSound = love.audio.newSource("insumos/SondsTrack/gameOver.mp3", "static")
    deathSound:setLooping(false)

    font = love.graphics.newFont(22)
    local margin = 20
    local buttonWidth, buttonHeight = 200, 55

    -- Botões do Menu
    buttons.exit.x = margin
    buttons.exit.y = love.graphics.getHeight() - buttonHeight - margin
    buttons.exit.width = buttonWidth
    buttons.exit.height = buttonHeight

    buttons.start.x = love.graphics.getWidth() - buttonWidth - margin
    buttons.start.y = love.graphics.getHeight() - buttonHeight - margin
    buttons.start.width = buttonWidth
    buttons.start.height = buttonHeight

    -- Botões do Game Over (centralizados)
    local centerX = love.graphics.getWidth() / 2
    local buttonY = love.graphics.getHeight() / 2 + 150 -- Posição vertical dos botões
    
    gameOverButtons.restart.x = centerX - buttonWidth - margin/2
    gameOverButtons.restart.y = buttonY
    gameOverButtons.restart.width = buttonWidth
    gameOverButtons.restart.height = buttonHeight

    gameOverButtons.menu.x = centerX + margin/2
    gameOverButtons.menu.y = buttonY
    gameOverButtons.menu.width = buttonWidth
    gameOverButtons.menu.height = buttonHeight
end

function drawMenu()

    love.graphics.setColor(1, 1, 1) 
    love.graphics.draw(backgroundMenu, 0, 0, 0, 
                      love.graphics.getWidth() / backgroundMenu:getWidth(),
                      love.graphics.getHeight() / backgroundMenu:getHeight())

    love.graphics.setFont(font)

    -- Desenhar botões
    for _, button in pairs(buttons) do
        -- Fundo do botão (preto semi-transparente)
        love.graphics.setColor(0, 0, 0, 0.75)  -- RGBA
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10)
        
        -- Texto vermelho (apenas aqui)
        love.graphics.setColor(1, 1, 1)  -- Vermelho
        love.graphics.printf(button.text, button.x, button.y + button.height/2 - 15, button.width, "center")
        
        -- Resetar cor para branco após desenhar o texto
        love.graphics.setColor(1, 1, 1)
    end
end

function checkButtonClick(x, y)
    for name, button in pairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height then
            return name
        end
    end
    return nil
end

-- Variáveis globais
local jogo

function drawGameOver()
    -- 1. Primeiro desenha o jogo (fundo normal)
    jogo:draw()
    
    -- 2. Camada escura sobre TODA a tela (não apenas metade)
    love.graphics.setColor(0, 0, 0, 0.5) -- Preto com 70% de opacidade
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- 3. Desenha a imagem de Game Over (se quiser manter)
    love.graphics.setColor(1, 1, 1) -- Cor normal
    love.graphics.draw(gameOverBackground, 0, 0, 0, 
                      love.graphics.getWidth() / gameOverBackground:getWidth(),
                      love.graphics.getHeight() / gameOverBackground:getHeight())
    
    -- 4. Área dos botões (opcional, para melhor contraste)
    love.graphics.setColor(0, 0, 0, 0.5)
    local buttonAreaHeight = 200 -- Altura da área dos botões
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - buttonAreaHeight, 
                          love.graphics.getWidth(), buttonAreaHeight)
    
    -- 5. Desenha os botões
    love.graphics.setFont(font)
    for _, button in pairs(gameOverButtons) do
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10)
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf(button.text, button.x, button.y + button.height/2 - 12, button.width, "center")
    end
    love.graphics.setColor(1, 1, 1) -- Reseta a cor
end

function love.load()
    loadMenu()
    jogo = Jogo:new()   
    jogo:load()
    deathSound:stop()
    -- Carrega o som da moeda (adicione esta linha)
    coinSound = love.audio.newSource("insumos/SondsTrack/powerUp.mp3", "static")
    if not coinSound then
        print("ERRO: Não foi possível carregar o som da moeda!")
    end

end

function love.update(dt)
    if deathSoundFade > 0 then
        deathSoundFade = deathSoundFade - dt
        deathSound:setVolume(deathSoundFade)
        if deathSoundFade <= 0 then
            deathSoundFade = 1.0
        end
    end

if currentGameState == gameStates.PLAYING then
    jogo:update(dt)
    
    -- Verifica se o personagem morreu E a animação terminou
    if jogo.personagem.morreu and jogo.personagem.deathAnimationComplete and currentGameState ~= gameStates.GAME_OVER then
        currentGameState = gameStates.GAME_OVER
        if not deathSound:isPlaying() then -- Só toca se não estiver já tocando
            deathSound:play()
        end
    end
end
end

function love.draw()
    if currentGameState == gameStates.MENU then
        drawMenu()
    elseif currentGameState == gameStates.PLAYING then
        jogo:draw()
    elseif currentGameState == gameStates.GAME_OVER then
        jogo:draw() -- Desenha o jogo por trás
        drawGameOver() -- Desenha a tela de game over por cima
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        if currentGameState == gameStates.MENU then
            local clicked = checkButtonClick(x, y)
            if clicked == "start" then
                currentGameState = gameStates.PLAYING
                musicMenu:stop()
                -- Reinicia o jogo
                jogo = Jogo:new()
                jogo:load()
            elseif clicked == "exit" then
                love.event.quit()
            end
        elseif currentGameState == gameStates.GAME_OVER then
            -- Verifica cliques nos botões do Game Over
            for name, button in pairs(gameOverButtons) do
                if x >= button.x and x <= button.x + button.width and
                   y >= button.y and y <= button.y + button.height then
                    if name == "restart" then
                        currentGameState = gameStates.PLAYING
                        deathSound:stop() -- Para a música de Game Over
                        jogo = Jogo:new()
                        jogo:load()
                        jogo.personagem.deathAnimationComplete = false
                    elseif name == "menu" then
                        currentGameState = gameStates.MENU
                        deathSound:stop() -- Para a música de Game Over
                        musicMenu:play() -- Reinicia a música do menu
                    end
                end
            end
        elseif currentGameState == gameStates.PLAYING then
            if button == 2 then
                jogo.personagem:iniciarDefesa()
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 2 and not menuState then
        jogo.personagem:pararDefesa()
    end
end


function Jogo:drawDebug()
    -- Hitbox do ataque do personagem
    if jogo.personagem:estaAtacando() and jogo.personagem:frameDeDano() then
        local p = jogo.personagem
        local ataqueLargura = 120
        local ataqueAltura = 80
        local ataqueOffsetX = p.direcao and 80 or -80
        local ataqueX = p.posX + ataqueOffsetX - ataqueLargura/2 - self.cameraX
        local ataqueY = p.posY + 180  -- Mesmo valor usado na colisão

        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", ataqueX, ataqueY, ataqueLargura, ataqueAltura)
    end
    
    -- Hitbox dos lobos
    for _, lobo in ipairs(self.lobosController.lobos) do
        if lobo.ativo and lobo.estado ~= "morte" then
            local loboLargura = 80
            local loboAltura = 60
            local loboX = lobo.x - loboLargura/2 + 30 - self.cameraX  -- Mesmo offset da colisão
            local loboY = lobo.y - 10  -- Mesmo offset da colisão

            love.graphics.setColor(0, 1, 0, 0.5)
            love.graphics.rectangle("fill", loboX, loboY, loboLargura, loboAltura)
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function love.keypressed(key)
    if currentGameState == gameStates.PLAYING then
        if key == "e" and not jogo.personagem:estaAtacando() and not jogo.personagem.defendendo then
            jogo.personagem.estado = "atacar2"
            jogo.personagem.animacaoAtaque2:gotoFrame(1)
            jogo.personagem.danoAplicado = false
        end
    end
end


-- PROXIMOS PASSOS:
--
-- 1. Colocar uma tela inicial do game, para startar ou fechar o jogo - OK 
--2. assim que o personagem principal morrer, abrir uma tela de "Lose" com a opção de reiniciar a fase ou voltar ao menu
--3. fazer a tabela do lobo, para spawnar mais lobos com forme avanço da fasae
--4. começar a trabalhar na "fase 2" que sera o combate contra o BOSS