local auth_window

local registered_serials = 0

local function isValidEmail(email)
    local pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+%.[a-zA-Z]+$"
    return email:match(pattern) ~= nil
end

local function alert( message )
    local alert_window = guiCreateWindow( 0.4, 0.45, 0.2, 0.1, "Предупреждение", true )
    local message_label = guiCreateLabel( 0, 0.3, 1, 0.3, message, true, alert_window )
    guiLabelSetHorizontalAlign( message_label, "center" )

    local close_button = guiCreateButton( 0.2, 0.6, 0.6, 0.3, "Закрыть", true, alert_window )
    addEventHandler( "onClientGUIClick", close_button, function ()
        destroyElement( alert_window )
    end, false )
end

local function draw_auth_window()
    showCursor( true )
	auth_window = guiCreateWindow( 0.3, 0.3, 0.4, 0.4, "Окно входа", true )
	local tab_panel = guiCreateTabPanel( 0, 0.1, 1, 1, true, auth_window )
	local tab_sign_up = guiCreateTab( "Регистрация", tab_panel )
    local tab_sign_in = guiCreateTab( "Вход", tab_panel )

    -- Sign up gui
    guiCreateLabel( 0.1, 0.05, 0.94, 0.92, "Почта", true, tab_sign_up )
    local email_edit = guiCreateEdit( 0.1, 0.1, 0.8, 0.1, "", true, tab_sign_up )
    guiCreateLabel( 0.1, 0.25, 0.94, 0.92, "Пароль", true, tab_sign_up )
    local password_edit = guiCreateEdit( 0.1, 0.3, 0.8, 0.1, "", true, tab_sign_up )
    guiCreateLabel( 0.1, 0.45, 0.94, 0.92, "Повторите пароль", true, tab_sign_up )
    local password_rep_edit = guiCreateEdit( 0.1, 0.5, 0.8, 0.1, "", true, tab_sign_up )

    local submit_button = guiCreateButton( 0.35, 0.7, 0.3, 0.1, "Зарегистрироваться", true, tab_sign_up )
    addEventHandler( "onClientGUIClick", submit_button, function ()
        local email = guiGetText( email_edit )
        local password = guiGetText( password_edit )
        local password_rep = guiGetText( password_rep_edit )
        local serial = getPlayerSerial( localPlayer )

        if registered_serials >= 3 then
            alert( "Вы создали слишком много учетных записей" )
            return
        end

        if not isValidEmail( email ) then
            alert( "Некорректный формат почты" )
            return
        end

        if #password < 8 then
            alert( "Пароль меньше 8-ми символов" )
            return
        end

        if password ~= password_rep then
            alert( "Пароли не совпадают" )
            return
        end

        destroyElement( auth_window )
        showCursor( false )
        triggerServerEvent( "onPlayerSignUp", resourceRoot, localPlayer, email, password, serial )
    end, false )

    -- Sign in gui
    guiCreateLabel( 0.1, 0.05, 0.94, 0.92, "Почта", true, tab_sign_in )
    local email_edit_sign_in = guiCreateEdit( 0.1, 0.1, 0.8, 0.1, "", true, tab_sign_in )
    guiCreateLabel( 0.1, 0.25, 0.94, 0.92, "Пароль", true, tab_sign_in )
    local password_edit_sign_in = guiCreateEdit( 0.1, 0.3, 0.8, 0.1, "", true, tab_sign_in )

    local submit_button_sign_in = guiCreateButton( 0.35, 0.7, 0.3, 0.1, "Войти", true, tab_sign_in )
    addEventHandler( "onClientGUIClick", submit_button_sign_in, function ()
        local email = guiGetText(email_edit_sign_in)
        local password = guiGetText(password_edit_sign_in)

        triggerServerEvent( "onPlayerRequestValidation", resourceRoot, localPlayer, email, password )
    end, false )
end

local function fetch_serial_data()
    triggerServerEvent( "onPlayerRequestSerials", resourceRoot, localPlayer )
end

local function load_start_resource()
    fetch_serial_data()
    draw_auth_window()
end

addEventHandler( "onClientResourceStart", resourceRoot, load_start_resource )

local function get_serials( serials )
    registered_serials = serials
end

addEvent( "onPlayerFetchSerials", true )
addEventHandler( "onPlayerFetchSerials", resourceRoot, get_serials )

local function sign_in( result )
    if result then
        destroyElement( auth_window )
        showCursor( false )
        triggerServerEvent( "onPlayerSignIn", resourceRoot, localPlayer )
    else
        alert( "Неверные почта/пароль" )
    end
end

addEvent( "onPlayerFetchValidation", true )
addEventHandler( "onPlayerFetchValidation", resourceRoot, sign_in )