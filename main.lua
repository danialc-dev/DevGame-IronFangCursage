local anim = require 'anim8'

local background

--set das imagens e animações de cada sprite do personagem principal
local imagemEstatico, animacaoEstatico
local imagemDefender, animacaoDefender
local imagemAndar, animacaoAndar
local imagemCorrer, animacaoCorrer
local imagemPular, animacaoPular
local imagemAtaque1, animacaoAtaque1
local imagemAtaque2, animacaoAtaque2
local imagemMorte, animacaoMorte
local imagemDano, animacaoDano

-- variaveis de auxilio do ataque
local tempoAtaque = 0
local duracaoAtaque = 0.7

local posX = 100
local posY = 146
local direcao = true
local estado = "andar"
local emChao = true
local puloVelocidade = -350
local gravidade = 800

local cameraX = 0

-- ataque e dano personagem
local vidaPersonagem = 100
local podeTomarDano = true
local tempoInvulnerabilidade = 1 -- ficara 1 segundo invulneravel apos tomar 1 dano (para que nao morra instantaneamente)
local tempoDano = 0
local morreu = false

--set das imagens e animações de cada sprite do LOBO
local imagemWolfEstatico, animacaoWolfEstatico
local imagemWolfRun, animacaoWolfRun
local imagemWolfAtaque, animacaoWolfAtaque
local posicaoLoboX = 200
local posicaoLoboY = 335
local loboDirecao = false
local loboSpawnado = false
local loboEstado = "correr"

local vidaLobo = 80


function love.load()
    background = love.graphics.newImage("insumos/Background/background.png")
    larguraBg = background:getWidth()

    function desenharSprite(animacao, imagem, x, y, direcao, cameraX, offsetX)
        local escalaX = direcao and 2 or -2
        local offset = offsetX or 48
        animacao:draw(imagem, x - cameraX, y, 0, escalaX, 2, offset, 0)
    end

    -- Personagem principal
    imagemEstatico = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Idle.png")
    local estatico = anim.newGrid(127, 128, imagemEstatico:getWidth(), imagemEstatico:getHeight())
    animacaoEstatico = anim.newAnimation(estatico('1-'..math.floor(imagemEstatico:getWidth() / 127), 1), 0.13)

    imagemAndar = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Walk.png")
    local walk = anim.newGrid(127, 128, imagemAndar:getWidth(), imagemAndar:getHeight())
    animacaoAndar = anim.newAnimation(walk('1-5', 1), 0.13)

    imagemCorrer = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Run.png")
    local run = anim.newGrid(127, 128, imagemCorrer:getWidth(), imagemCorrer:getHeight())
    animacaoCorrer = anim.newAnimation(run('1-'..math.floor(imagemCorrer:getWidth() / 127), 1), 0.09)

    imagemPular = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Jump.png")
    local jump = anim.newGrid(127, 128, imagemPular:getWidth(), imagemPular:getHeight())
    animacaoPular = anim.newAnimation(jump('1-'..math.floor(imagemPular:getWidth() / 127), 1), 0.1)

    imagemDefender = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Protect.png")
    local defend = anim.newGrid(127, 128, imagemDefender:getWidth(), imagemDefender:getHeight())
    animacaoDefender = anim.newAnimation(defend('1-'..math.floor(imagemDefender:getWidth() / 127), 1), 0.1)

    imagemAtaque1 = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Attack3.png")
    local ataque1 = anim.newGrid(127, 128, imagemAtaque1:getWidth(), imagemAtaque1:getHeight())
    animacaoAtaque1 = anim.newAnimation(ataque1('1-'..math.floor(imagemAtaque1:getWidth() / 127), 1), 0.12)

    imagemAtaque2 = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Attack1.png")
    local ataque2 = anim.newGrid(128, 128, imagemAtaque2:getWidth(), imagemAtaque2:getHeight())
    animacaoAtaque2 = anim.newAnimation(ataque2('1-'..math.floor(imagemAtaque2:getWidth() / 127), 1), 0.14)

    imagemMorte = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Dead.png")
    local morte = anim.newGrid(128, 128, imagemMorte:getWidth(), imagemMorte:getHeight())
    animacaoMorte = anim.newAnimation(morte('1-'..math.floor(imagemMorte:getWidth() / 128), 1), 0.14)

    imagemDano = love.graphics.newImage("insumos/Sprite_Person_princ/Spritesheet 128/Knight_1/Hurt.png")
    local dano = anim.newGrid(128, 128, imagemDano:getWidth(), imagemDano:getHeight())
    animacaoDano = anim.newAnimation(dano('1-'..math.floor(imagemDano:getWidth() / 128), 1), 0.14)

    -- Lobo
    imagemWolfEstatico = love.graphics.newImage("insumos/Sprite_Wolf/iddle.png")
    local loboEstatico = anim.newGrid(65, 41, imagemWolfEstatico:getWidth(), imagemWolfEstatico:getHeight())
    animacaoWolfEstatico = anim.newAnimation(loboEstatico('1-'..math.floor(imagemWolfEstatico:getWidth() / 96), 1), 0.18)

    imagemWolfRun = love.graphics.newImage("insumos/Sprite_Wolf/walk.png") 
    local wolfRun = anim.newGrid(66, 31, imagemWolfRun:getWidth(), imagemWolfRun:getHeight())
    animacaoWolfRun = anim.newAnimation(wolfRun('1-'..math.floor(imagemWolfRun:getWidth() / 96), 1), 0.18)

    imagemWolfAtaque = love.graphics.newImage("insumos/Sprite_Wolf/attack.png")
    local wolfAtaque = anim.newGrid(64, 32, imagemWolfAtaque:getWidth(), imagemWolfAtaque:getHeight())
    animacaoWolfAtaque = anim.newAnimation(wolfAtaque('1-'..math.floor(imagemWolfAtaque:getWidth() / 96), 1), 0.22)
end

function love.update(dt)
    local velocidade = 140
    local movendo = false

    -- Verifica se o lobo foi spawnado
    if not loboSpawnado and posX > 300 then
        loboSpawnado = true
        posicaoLoboX = posX + 300 -- spawna a frente do personagem
    end

    if loboSpawnado then
        local distancia = math.abs(posicaoLoboX - posX)
    
        if distancia > 30 then
            posicaoLoboX = posicaoLoboX - 120 * dt -- anda para a esquerda
            loboEstado = "correr"
            animacaoWolfRun:update(dt)
            loboDirecao = false -- olhando para a esquerda
        else
            loboEstado = "atacar"
            animacaoWolfAtaque:update(dt)
        end
    end

    -- função para tirar a vida do personagem caso o lobo ataque ele
    if loboSpawnado and loboEstado == "atacar" then
        if podeTomarDano and not (estado == "defender") then
            vidaPersonagem = vidaPersonagem - 10  -- O dano é aplicado
            podeTomarDano = false
            tempoDano = tempoInvulnerabilidade
            estado = "dano"  -- Muda o estado para "dano"
        end
    end
    
    -- Atualiza o tempo de invulnerabilidade após o dano
    if not podeTomarDano then
        tempoDano = tempoDano - dt
        if tempoDano <= 0 then
            podeTomarDano = true
            if estado == "dano" then
                estado = "estatico"  -- Volta para estado normal após dano
            end
        end
    end
    
    -- vida chegando a 0 atualiza a variavel MORTE para true
    if vidaPersonagem <= 0 and not morreu then
        morreu = true
        estado = "morte"  -- Estado para animação de morte
    end
    
    if love.keyboard.isDown('space') and emChao and estado ~= "morte" then
        estado = "pular"
        emChao = false
        puloVelocidade = -350
    end
    
    if not emChao then
        posY = posY + puloVelocidade * dt
        puloVelocidade = puloVelocidade + gravidade * dt
        if posY >= 146 then
            posY = 146
            emChao = true
            puloVelocidade = -230
            if estado == "pular" then
                estado = "estatico"
            end
        end
    end

    -- Condicional para atualizar o estado de movimento ou ataque
    if estado ~= "dano" and estado ~= "morte" and estado ~= "pular" then
        -- Ataque com botão esquerdo do mouse (independente)
        if love.mouse.isDown(1) and estado ~= "atacar" and estado ~= "atacar2" then
            estado = "atacar"
            animacaoAtaque1:gotoFrame(1)
        end
        
        -- Ataque com tecla E (independente)
        if love.keyboard.isDown("e") and estado ~= "atacar" and estado ~= "atacar2" then
            estado = "atacar2"
            animacaoAtaque2:gotoFrame(1)
        end
        
        -- Movimento normal (apenas se não estiver atacando)
        if estado ~= "atacar" and estado ~= "atacar2" then
            if love.keyboard.isDown('a') or love.keyboard.isDown('d') then
                if love.keyboard.isDown("lshift") then
                    estado = "correr"
                    velocidade = 200
                    direcao = not love.keyboard.isDown("a")
                else
                    estado = "andar"
                    velocidade = 140
                    direcao = not love.keyboard.isDown("a")
                end
            else
                estado = "estatico"
            end
        end
    end

    -- Movimentação do personagem
    if estado ~= "dano" and estado ~= "morte" then
        if love.keyboard.isDown("a") then
            posX = posX - velocidade * dt
            movendo = true
        elseif love.keyboard.isDown("d") then
            posX = posX + velocidade * dt
            movendo = true
        end
    end

    -- Atualiza as animações
    if estado == "dano" then
        animacaoDano:update(dt)
    elseif estado == "morte" then
        animacaoMorte:update(dt)  
    elseif estado == "estatico" then
        animacaoEstatico:update(dt)
    elseif estado == "defender" then
        animacaoDefender:update(dt)
    elseif estado == "atacar" then
        animacaoAtaque1:update(dt)
        if animacaoAtaque1.position == #animacaoAtaque1.frames then
            estado = "estatico"  -- Volta ao normal após terminar
        end
        
    elseif estado == "atacar2" then
        animacaoAtaque2:update(dt)
        if animacaoAtaque2.position == #animacaoAtaque2.frames then
            estado = "estatico"  -- Volta ao normal após terminar
        end
    elseif not emChao then
        animacaoPular:update(dt)
    elseif estado == "andar" then
        animacaoAndar:update(dt)
    elseif estado == "correr" then
        animacaoCorrer:update(dt)
    end

    -- Atualiza a posição da câmera com o personagem
    cameraX = posX - love.graphics.getWidth() / 2
end

function love.draw()
    local startX = -(cameraX % larguraBg)
    for i = -1, 2 do
        love.graphics.draw(background, startX + i * larguraBg, 0)
    end

    -- Atualização da escolha da animação
    local animacao
    local imagem
    
    if estado == "dano" then
        animacao = animacaoDano
        imagem = imagemDano
    elseif estado == "morte" then
        animacao = animacaoMorte
        imagem = imagemMorte
    elseif estado == "defender" then
        animacao = animacaoDefender
        imagem = imagemDefender
    elseif estado == "estatico" then
        animacao = animacaoEstatico
        imagem = imagemEstatico
    elseif estado == "atacar" then
        animacao = animacaoAtaque1
        imagem = imagemAtaque1
    elseif estado == "atacar2" then
        animacao = animacaoAtaque2
        imagem = imagemAtaque2
    elseif not emChao then
        animacao = animacaoPular
        imagem = imagemPular
    elseif estado == "andar" then
        animacao = animacaoAndar
        imagem = imagemAndar
    elseif estado == "correr" then
        animacao = animacaoCorrer
        imagem = imagemCorrer
    end

    -- Chama a função de desenhar o sprite com a animação correta
    desenharSprite(animacao, imagem, posX, posY, direcao, cameraX, 48)

    if loboSpawnado then
        if loboEstado == "correr" then
            desenharSprite(animacaoWolfRun, imagemWolfRun, posicaoLoboX, posicaoLoboY, loboDirecao, cameraX, 32)
        elseif loboEstado == "atacar" then
            desenharSprite(animacaoWolfAtaque, imagemWolfAtaque, posicaoLoboX, posicaoLoboY, loboDirecao, cameraX, 32)
        end
    end
    -- desenhando a barra de vida do personagem
    love.graphics.setColor(1, 0, 0) -- vermelho
    love.graphics.rectangle("fill", 10, 10, vidaPersonagem * 2, 20)
    love.graphics.setColor(1, 1, 1) -- volta para branco
end
