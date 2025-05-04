local anim = require 'anim8'

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
    }
    self.__index = self
    return setmetatable(o, self)
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
    self.animacaoAtaque2 = anim.newAnimation(ataque2('1-'..math.floor(self.imagemAtaque2:getWidth() / 127), 1), 0.14)

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
        return self.animacaoAtaque1.position >= 3 and self.animacaoAtaque1.position <= 5
    elseif self.estado == "atacar2" then
        return self.animacaoAtaque2.position >= 2 and self.animacaoAtaque2.position <= 4
    end
    return false
end

function Personagem:colisaoComLobo()
    if not self.lobo or self.lobo.estado == "morte" then return false end
    
    -- Hitbox do personagem durante o ataque
    local ataqueLargura = 100
    local ataqueAltura = 150
    local ataqueOffsetX = self.direcao and 60 or -60
    
    -- Hitbox do lobo
    local loboLargura = 60
    local loboAltura = 40
    local loboOffsetY = 30
    
    -- Posição da hitbox de ataque
    local ataqueX = self.posX + ataqueOffsetX
    local ataqueY = self.posY - 20
    
    -- Posição da hitbox do lobo
    local loboX = self.lobo.x
    local loboY = self.lobo.y + loboOffsetY
    
    -- Verifica colisão
    return ataqueX < loboX + loboLargura and
           ataqueX + ataqueLargura > loboX and
           ataqueY < loboY + loboAltura and
           ataqueY + ataqueAltura > loboY
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
    
    -- Atualiza o cooldown do dano ao lobo
    if self.loboDanoCooldown then
        self.tempoLoboDanoCooldown = self.tempoLoboDanoCooldown - dt
        if self.tempoLoboDanoCooldown <= 0 then
            self.loboDanoCooldown = false
        end
    end
    
    -- Verificação de morte
    if self.vida <= 0 and not self.morreu then
        self.morreu = true
        self.estado = "morte"
        self.animacaoMorte:gotoFrame(1)
        love.audio.play(deathSound) -- Toca o som de morte
        self.deathAnimationComplete = false -- Flag para controlar término da animação
    end
    
    -- Se estiver morto
    if self.morreu then
        -- Atualiza animação se ainda não terminou
        if not self.deathAnimationComplete then
            self.animacaoMorte:update(dt)
            if self.animacaoMorte.position == #self.animacaoMorte.frames then
                self.deathAnimationComplete = true -- Marca animação como completa
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

    -- Condicional para atualizar o estado de movimento ou ataque
    if self.defendendo then
        self.estado = "defender"
    elseif self.estado ~= "dano" and self.estado ~= "morte" and self.estado ~= "pular" then
        if love.mouse.isDown(2) and not self.defendendo and self.estado ~= "atacar" and self.estado ~= "atacar2" then
            self:iniciarDefesa()
        end

        -- Ataque com botão esquerdo do mouse
        if love.mouse.isDown(1) and self.estado ~= "atacar" and self.estado ~= "atacar2" then
            self.estado = "atacar"
            self.animacaoAtaque1:gotoFrame(1)
        end
    
        -- Ataque com a tecla "E"
        if love.keyboard.isDown("e") and self.estado ~= "atacar" and self.estado ~= "atacar2" then
            self.estado = "atacar2"
            self.animacaoAtaque2:gotoFrame(1)
        end
    
        -- Verificação de colisão e dano ao lobo
        if self:estaAtacando() and self:frameDeDano() and not self.loboDanoCooldown then
            if self:colisaoComLobo() and self.lobo.podeTomarDano then
                if self.estado == "atacar" then
                    self.lobo:tomarDano(20)
                elseif self.estado == "atacar2" then
                    self.lobo:tomarDano(40)
                end
                self.loboDanoCooldown = true
                self.tempoLoboDanoCooldown = 0.3
            end
        end       
        
        -- Movimento normal
        if self.estado ~= "atacar" and self.estado ~= "atacar2" then
            if love.keyboard.isDown('a') or love.keyboard.isDown('d') then
                if love.keyboard.isDown("lshift") then
                    self.estado = "correr"
                    self.velocidade = 200
                    self.direcao = not love.keyboard.isDown("a")
                else
                    self.estado = "andar"
                    self.velocidade = 140
                    self.direcao = not love.keyboard.isDown("a")
                end
            else
                self.estado = "estatico"
            end
        end
    end

    -- Movimentação
    if self.estado ~= "dano" and self.estado ~= "morte" then
        if love.keyboard.isDown("a") then
            self.posX = self.posX - self.velocidade * dt
        elseif love.keyboard.isDown("d") then
            self.posX = self.posX + self.velocidade * dt
        end
    end

    -- Atualiza as animações
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
        if self.animacaoAtaque2.position == #self.animacaoAtaque2.frames then
            self.estado = "estatico"
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
        podeTomarDano = true
    }
    self.__index = self
    return setmetatable(o, self)
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
    self.animacaoHurt = anim.newAnimation(hurt('1-'..math.floor(self.imagemHurt:getWidth() / 96), 1), 0.15)
end

function Lobo:tomarDano(dano)
    if not self.podeTomarDano then 
        print("Lobo invulnerável no momento")
        return 
    end
    
    self.vida = math.max(0, self.vida - dano)
    print(string.format("Lobo tomou %d de dano! Vida restante: %d", dano, self.vida))
    
    if self.vida > 0 then
        self.estado = "hurt"
        self.animacaoHurt:gotoFrame(1)
        self.tempoHurt = 0.5
        self.podeTomarDano = false
    else
        print("LOBO DERROTADO!")
        self.estado = "morte"
    end
end

function Lobo:update(dt, personagem)
    if self.estado == "morte" then return end

    if not self.spawnado and personagem.posX > 300 then
        self.spawnado = true
        self.x = personagem.posX + 300
    end

    if self.spawnado then
        -- Atualizar tempo de hurt
        if self.estado == "hurt" then
            self.tempoHurt = self.tempoHurt - dt
            if self.tempoHurt <= 0 then
                self.estado = "correr"
                self.podeTomarDano = true
            end
            self.animacaoHurt:update(dt)
            return
        end

        local distancia = math.abs(self.x - personagem.posX)
    
        if distancia > 60 then
            self.x = self.x - 120 * dt
            self.estado = "correr"
            self.animacaoRun:update(dt)
            self.direcao = false
            self.tempoAtaque = 0
        else
            self.estado = "atacar"
            self.animacaoAtaque:update(dt)
            
            if self.animacaoAtaque.position == 1 then
                self.danoAplicado = false
            end
        
            if self.animacaoAtaque.position == 3 and not self.danoAplicado then
                self.danoAplicado = true
        
                if personagem.podeTomarDano and not (personagem.estado == "defender") then
                    personagem.vida = personagem.vida - 15
                    personagem.podeTomarDano = false
                    personagem.tempoDano = personagem.tempoInvulnerabilidade
                    personagem.estado = "dano"
                elseif personagem.estado == "defender" then
                    -- Defesa bem-sucedida
                end
                self.tempoAtaque = 0
            end
        end
    end
end

function Lobo:draw(cameraX)
    if not self.spawnado or self.estado == "morte" then return end
    
    local escalaX = self.direcao and 2 or -2
        
    if self.estado == "correr" then
        self.animacaoRun:draw(self.imagemRun, self.x - cameraX, self.y, 0, escalaX, 2, 32, 0)
    elseif self.estado == "atacar" then
        self.animacaoAtaque:draw(self.imagemAtaque, self.x - cameraX, self.y, 0, escalaX, 2, 32, 0)
    elseif self.estado == "hurt" then
        self.animacaoHurt:draw(self.imagemHurt, self.x - cameraX, self.y, 0, escalaX, 2, 32, 0)
    end

    -- Barra de vida
    local barraVidaX = self.x - cameraX - 20
    local barraVidaY = self.y - 25
    local barraVidaLargura = self.vida / 80 * 50

    love.graphics.setColor(1, 0, 0) 
    love.graphics.rectangle("fill", barraVidaX, barraVidaY, barraVidaLargura, 6)
    love.graphics.setColor(1, 1, 1)
end

-- Classe do Jogo
local Jogo = {}
function Jogo:new()
    local o = {
        background = nil,
        larguraBg = 0,
        cameraX = 0,
        personagem = Personagem:new(),
        lobo = Lobo:new()
    }
    setmetatable(o, self)
    self.__index = self
    
    o.personagem.lobo = o.lobo
    
    return o
end

function Jogo:load()
    self.background = love.graphics.newImage("insumos/Background/background.png")
    self.larguraBg = self.background:getWidth()
    self.personagem:load()
    self.lobo:load()
end

function Jogo:update(dt)
    self.personagem:update(dt)
    self.lobo:update(dt, self.personagem)
    self.cameraX = self.personagem.posX - love.graphics.getWidth() / 2
end

function Jogo:draw()
    -- Desenha o background
    local startX = -(self.cameraX % self.larguraBg)
    for i = -1, 2 do
        love.graphics.draw(self.background, startX + i * self.larguraBg, 0)
    end

    -- Desenha os personagens
    self.lobo:draw(self.cameraX)
    self.personagem:draw(self.cameraX)

    -- Barra de vida do personagem
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", 10, 10, self.personagem.vida * 2, 20)
    love.graphics.setColor(1, 1, 1)

    -- Debug info
    love.graphics.print("Estado Personagem: " .. self.personagem.estado, 10, 40)
    love.graphics.print("Estado Lobo: " .. self.lobo.estado, 10, 60)
    love.graphics.print("Vida Lobo: " .. self.lobo.vida, 10, 80)

    self:drawDebug() 
end

-- Funções para o menu
function loadMenu()
    backgroundMenu = love.graphics.newImage("insumos/BackgroundMenu/menu2.png") 
    musicMenu = love.audio.newSource("insumos/SondsTrack/ForestTheme.mp3", "stream")
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
        love.graphics.setColor(1, 0, 0)  -- Vermelho
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
        local ataqueLargura = 100
        local ataqueAltura = 150
        local ataqueOffsetX = p.direcao and 60 or -60
        local ataqueX = p.posX + ataqueOffsetX - jogo.cameraX
        local ataqueY = p.posY - 20
        
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", ataqueX, ataqueY, ataqueLargura, ataqueAltura)
    end
    
    -- Hitbox do lobo
    if jogo.lobo.spawnado and jogo.lobo.estado ~= "morte" then
        local l = jogo.lobo
        local loboLargura = 60
        local loboAltura = 40
        local loboX = l.x - jogo.cameraX
        local loboY = l.y + 30
        
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.rectangle("fill", loboX, loboY, loboLargura, loboAltura)
    end
    love.graphics.setColor(1, 1, 1)
end



-- PROXIMOS PASSOS:
--
-- 1. Colocar uma tela inicial do game, para startar ou fechar o jogo - OK 
--2. assim que o personagem principal morrer, abrir uma tela de "Lose" com a opção de reiniciar a fase ou voltar ao menu
--3. fazer a tabela do lobo, para spawnar mais lobos com forme avanço da fasae
--4. começar a trabalhar na "fase 2" que sera o combate contra o BOSS