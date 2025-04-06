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
local posY = 230  -- Aqui você controla a posição vertical
local direcao = true
local estado = "andar"  -- Pode ser "andar", "correr", "pular"
local emChao = true  -- Variável para verificar se o personagem está no chão
local puloVelocidade = -350  -- A velocidade do pulo (ajuste para pular mais alto)
local gravidade = 800  -- A aceleração da gravidade

local cameraX = 0 --criar a camera para acompanhar o personagem com forme ele anda 

function love.load()
    -- setando a imagem do background
    background = love.graphics.newImage("insumos/Background/background.png")
    larguraBg = background:getWidth()

    -- função para espelhar os sprites
    function desenharSprite(animacao, imagem, x, y, direcao, cameraX, offsetX)
        local escalaX = direcao and 2 or -2
        local offset = direcao and offsetX or (offsetX - 90)  -- <-- Ajuste fino 
        animacao:draw(imagem, x - cameraX, y, 0, escalaX, 2, offset, 0)
    end

    --Pegando a animação estatica do personagem
    imagemEstatico = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Idle1.png")
    local colunasEstatico = imagemEstatico:getWidth() / 72  -- Calcula quantas colunas tem
    local estatico = anim.newGrid(72, 86, imagemEstatico:getWidth(), imagemEstatico:getHeight())
    animacaoEstatico = anim.newAnimation(estatico('1-'..math.floor(colunasEstatico), 1), 0.08)

    -- Pegando a animação de andar
    imagemAndar = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Walk.png")
    local colunasWalk = imagemAndar:getWidth() / 75  -- Calcula quantas colunas tem
    local walk = anim.newGrid(75, 86, imagemAndar:getWidth(), imagemAndar:getHeight())
    animacaoAndar = anim.newAnimation(walk('1-5', 1), 0.13)

    -- Pegando a animação de correr
    imagemCorrer = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Run.png")
    local colunasRun = imagemCorrer:getWidth() / 72  -- Calcula quantas colunas tem
    local run = anim.newGrid(72, 86, imagemCorrer:getWidth(), imagemCorrer:getHeight())
    animacaoCorrer = anim.newAnimation(run('1-'..math.floor(colunasRun), 1), 0.08)

    -- Pegando a animação de pular
    imagemPular = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Jump.png")
    local colunasJump = imagemPular:getWidth() / 72
    local jump = anim.newGrid (80, 86, imagemPular:getWidth(), imagemPular:getHeight())
    animacaoPular = anim.newAnimation(jump('1-'..math.floor(colunasJump), 1), 0.1)

    -- Pegando a animação de defender
    imagemDefender = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Protect.png")
    local colunasDefend = imagemDefender:getWidth() / 72  -- Ajuste aqui para garantir que você tenha o número certo de colunas
    local defend = anim.newGrid(72, 86, imagemDefender:getWidth(), imagemDefender:getHeight()) -- Certifique-se de usar as dimensões corretas
    animacaoDefender = anim.newAnimation(defend('1-'..math.floor(colunasDefend), 1), 0.1)

    -- Pegando a imagem do ataque 1
    imagemAtaque1 = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Attack3.png")
    local colunasAtaque1 = imagemAtaque1:getWidth() / 102  -- Ajuste aqui para garantir que você tenha o número certo de colunas
    local ataque1 = anim.newGrid(102, 86, imagemAtaque1:getWidth(), imagemAtaque1:getHeight()) -- Certifique-se de usar as dimensões corretas
    animacaoAtaque1 = anim.newAnimation(ataque1('1-'..math.floor(colunasAtaque1), 1), 0.12)

    --Pegando a imagem do ataque 2
    imagemAtaque2 = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Attack1.png")
    local colunasAtaque2 = imagemAtaque2:getWidth() / 86  -- Ajuste aqui para garantir que você tenha o número certo de colunas
    local ataque2 = anim.newGrid(86, 86, imagemAtaque2:getWidth(), imagemAtaque2:getHeight()) -- Certifique-se de usar as dimensões corretas
    animacaoAtaque2 = anim.newAnimation(ataque2('1-'..math.floor(colunasAtaque2), 1), 0.18)

    --Carregando a imagem de morte (vai ser usada na implementação de vida = 0 do personagem)
    imagemMorte = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Dead.png")
    local colunasMorte = imagemMorte:getWidth() / 80  -- Ajuste aqui para ga2rantir que você tenha o número certo de colunas
    local morte = anim.newGrid(80, 86, imagemMorte:getWidth(), imagemMorte:getHeight()) -- Certifique-se de usar as dimensões corretas
    animacaoMorte = anim.newAnimation(morte('1-'..math.floor(colunasMorte), 1), 0.18)

    --Carregando a imagem de dano (vai ser usada na implementação de dano ao personagem)
    imagemDano = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Hurt.png")
    local colunasDano = imagemDano:getWidth() / 70  -- Ajuste aqui para garantir que você tenha o número certo de colunas
    local dano = anim.newGrid(70, 86, imagemDano:getWidth(), imagemDano:getHeight()) -- Certifique-se de usar as dimensões corretas
    animacaoDano = anim.newAnimation(dano('1-'..math.floor(colunasDano), 1), 0.18)
end


function love.update(dt)
    local velocidade = 140
    local movendo = false  -- Variável para checar se o personagem está se movendo

    -- Verifica se o personagem está pulando
    if love.keyboard.isDown('space') and emChao then
        estado = "pular"
        emChao = false
        puloVelocidade = -350  -- Velocidade do pulo para "subir"
    end

    -- Atualiza a posição Y com a gravidade, fazendo o personagem cair
    if not emChao then
        posY = posY + puloVelocidade * dt
        puloVelocidade = puloVelocidade + gravidade * dt  -- Aplica a gravidade (faz o personagem cair)

        if posY >= 230 then  -- Quando o personagem atinge o chão (posição original)
            posY = 230
            emChao = true  -- O personagem agora está no chão
            puloVelocidade = -230  -- Reseta a velocidade do pulo
        end
    end

    -- Verifica o estado de movimento e impede a movimentação enquanto estiver defendendo

    if estado ~= "defender" and estado ~= "atacar" and estado ~= "atacar2" then
        if (love.keyboard.isDown("a") or love.keyboard.isDown("d")) and love.keyboard.isDown("lshift") then
            estado = "correr"
            velocidade = 240
        elseif love.keyboard.isDown("a") or love.keyboard.isDown("d") then
            estado = "andar"
            velocidade = 140
        else
            estado = "estatico"
        end
    
            if love.keyboard.isDown('a') then
            posX = posX - velocidade * dt
            cameraX = cameraX - velocidade * dt
            direcao = false
            movendo = true  -- Está se movendo
        end
        if love.keyboard.isDown('d') then
            posX = posX + velocidade * dt
            cameraX = cameraX + velocidade * dt
            direcao = true
            movendo = true  -- Está se movendo
        end
    end

    -- fazendo a animação do ataque 1
    if tempoAtaque > 0 then
        tempoAtaque = tempoAtaque - dt
        estado = "atacar"
    elseif tempoAtaque > 0 then
        tempoAtaque = tempoAtaque - dt
        estado = "atacar2"
    elseif not emChao then
        estado = "pular"
    elseif love.keyboard.isDown("e") then
        estado = "atacar2"
    elseif love.mouse.isDown(2) then
        estado = "defender"
    elseif love.mouse.isDown(1) then
        estado = "atacar"
        tempoAtaque = duracaoAtaque
        animacaoAtaque1:gotoFrame(1)
    elseif (love.keyboard.isDown("a") or love.keyboard.isDown("d")) and love.keyboard.isDown("lshift") then
        estado = "correr"
    elseif love.keyboard.isDown("a") or love.keyboard.isDown("d") then
        estado = "andar"
    else
        estado = "estatico"
    end

   

    -- Atualiza a animação com base no estado do personagem
    if estado == "estatico" then
        animacaoEstatico:update(dt)
    elseif estado == "defender" then
        animacaoDefender:update(dt)
    elseif estado == "atacar" then
        animacaoAtaque1:update(dt)
    elseif estado == "atacar2" then
        animacaoAtaque2:update(dt)
    elseif not emChao then
        animacaoPular:update(dt)
    elseif estado == "andar" then
        animacaoAndar:update(dt)
    elseif estado == "correr" then
        animacaoCorrer:update(dt)
    end

    -- Atualiza a posição da camera quando o personagem andar
    cameraX = posX - love.graphics.getWidth() / 2

end



function love.draw()
    -- Calcula a posição inicial do background corretamente
    local startX = -(cameraX % larguraBg)

    -- Renderiza o background **três vezes seguidas** para garantir que cubra a tela inteira
    for i = -1, 2 do
        love.graphics.draw(background, startX + i * larguraBg, 0)
    end

    -- Escolhe a animação de acordo com o estado
    local imagem = (estado == "andar") and imagemAndar or imagemCorrer
    local animacao = (estado == "andar") and animacaoAndar or animacaoCorrer

    -- Se estiver no ar, usa a animação de pular
    if estado == "defender" then
        desenharSprite(animacaoDefender, imagemDefender, posX, posY, direcao, cameraX, 90)
    elseif estado == "estatico" then
        desenharSprite(animacaoEstatico, imagemEstatico, posX, posY, direcao, cameraX, 90)
    elseif estado == "atacar" then
        desenharSprite(animacaoAtaque1, imagemAtaque1, posX, posY, direcao, cameraX, 90)
    elseif estado == "atacar2" then
        desenharSprite(animacaoAtaque2, imagemAtaque2, posX, posY, direcao, cameraX, 90)
    elseif not emChao then
        desenharSprite(animacaoPular, imagemPular, posX, posY, direcao, cameraX, 90)
    else
        desenharSprite(animacao, imagem, posX, posY, direcao, cameraX, 90)
    end
end

