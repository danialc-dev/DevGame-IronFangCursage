local anim = require 'anim8'

local background

local imagemDefender, animacaoDefender
local imagemAndar, animacaoAndar
local imagemCorrer, animacaoCorrer
local imagemPular, animacaoPular

local posX = 100
local posY = 230  -- Aqui você controla a posição vertical
local direcao = true
local estado = "andar"  -- Pode ser "andar", "correr", "pular"
local emChao = true  -- Variável para verificar se o personagem está no chão
local puloVelocidade = -350  -- A velocidade do pulo (ajuste para pular mais alto)
local gravidade = 800  -- A aceleração da gravidade

local cameraX = 0 --Vamos criar a camera para acompanhar o personagem com forme ele anda 

function love.load()
    -- setando a imagem do background
    background = love.graphics.newImage("insumos/Background/background.png")
    larguraBg = background:getWidth()

    -- Pegando a animação de andar
    imagemAndar = love.graphics.newImage("insumos/Sprite_Person_princ/Knight_1/Walk.png")
    local colunasWalk = imagemAndar:getWidth() / 72  -- Calcula quantas colunas tem
    local walk = anim.newGrid(72, 86, imagemAndar:getWidth(), imagemAndar:getHeight())
    animacaoAndar = anim.newAnimation(walk('1-5', 1), 0.1)

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
    if estado ~= "defender" then
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            estado = "correr"
            velocidade = 240
        else
            estado = "andar"
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

    -- fazendo a animação de defender
    if love.mouse.isDown(2) then
        estado = "defender"
    else
        -- Caso contrário, usa o comportamento normal (andar ou correr)
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            estado = "correr"
        else
            estado = "andar"
        end
    end

    -- Atualiza a animação com base no estado do personagem
    if movendo then
        if estado == "defender" then
            animacaoDefender:update(dt)
        elseif estado == "andar" then
            animacaoAndar:update(dt)
        elseif estado == "correr" then
            animacaoCorrer:update(dt)
        end
    elseif not emChao then
        -- Atualiza a animação de pulo quando estiver no ar
        animacaoPular:update(dt)
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
        -- Inverte a animação de defesa se a direção for para a esquerda
        if not direcao then
            animacaoDefender:draw(imagemDefender, posX - cameraX, posY, 0, -2, 2, 90, 0)  -- Inverte
        else
            animacaoDefender:draw(imagemDefender, posX - cameraX, posY, 0, 2, 2, 90, 0)  -- Normal
        end
    elseif not emChao then
        -- Se estiver no ar, usa a animação de pular
        if not direcao then
            animacaoPular:draw(imagemPular, posX - cameraX, posY, 0, -2, 2, 90, 0)  -- Inverte
        else
            animacaoPular:draw(imagemPular, posX - cameraX, posY, 0, 2, 2, 90, 0)  -- Normal
        end
    else
        -- Se estiver andando ou correndo
        if direcao then
            animacao:draw(imagem, posX - cameraX, posY, 0, 2, 2, 90, 0)
        else
            animacao:draw(imagem, posX - cameraX, posY, 0, -2, 2, 90, 0)
        end
    end
end

