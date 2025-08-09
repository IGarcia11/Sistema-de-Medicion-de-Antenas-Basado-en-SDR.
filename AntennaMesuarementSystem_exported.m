classdef AntennaMesuarementSystem_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        SistemadeMedicindeAntenaUIFigure  matlab.ui.Figure
        ArchivoMenu                  matlab.ui.container.Menu
        AbrirPatronRadiacionMenu     matlab.ui.container.Menu
        AbrirPatronRadiacion3DMenu   matlab.ui.container.Menu
        GuardarDatosSimMenu          matlab.ui.container.Menu
        SimulacinMenu                matlab.ui.container.Menu
        ADALMPLUTOMenu               matlab.ui.container.Menu
        RTLSDRMenu                   matlab.ui.container.Menu
        Graf3DButton                 matlab.ui.control.Button
        PlanoDropDown                matlab.ui.control.DropDown
        PlanoDropDownLabel           matlab.ui.control.Label
        NombreAntenaDropDown         matlab.ui.control.DropDown
        NombreAntenaDropDownLabel    matlab.ui.control.Label
        NivelSealdBmEditField        matlab.ui.control.NumericEditField
        NivelSealdBmEditFieldLabel   matlab.ui.control.Label
        PatrondeRadiacinPanel        matlab.ui.container.Panel
        FrecuenciaMHzEditField       matlab.ui.control.EditField
        FrecuenciaMHzEditFieldLabel  matlab.ui.control.Label
        IniciarMedicinButton         matlab.ui.control.Button
    end


    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end

    
    properties (Access = private)
        transdata % Description
        posdatanormH
        posdatanormV   
        H
        V
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: IniciarMedicinButton
        function IniciarMedicinButtonPushed(app, event)
            app.IniciarMedicinButton.Enable = "off";
            app.FrecuenciaMHzEditField.Value = ' ';
            app.NivelSealdBmEditField.Value = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ADAML-PLUTO
            if app.ADALMPLUTOMenu.Checked 
            modeloTR = 'transceiver';
            load_system(modeloTR)
            set_param(modeloTR, 'SimulationCommand', 'start', 'StopTime', '4.5');
           
            pause(1.4)
            Steppermotor();
            pause(25)
            app.FrecuenciaMHzEditField.Value = '2484';
             mivar = evalin("base","out");
            peak = zeros(512,1);
            for i = 1:512
                peak(i,1) = max(mivar.yout(560:600,1,i));
            end
            else % RTL-SDR
            modeloTR = 'transceiver_RTL';
            load_system(modeloTR)
            set_param(modeloTR, 'SimulationCommand', 'start', 'StopTime', '16');
           
            pause(2)
            Steppermotor();
            pause(25)
            app.FrecuenciaMHzEditField.Value = '915';
             mivar = evalin("base","out");
            peak = zeros(512,1);
            for i = 1:512
                peak(i,1) = max(mivar.yout(800:1000,1,i));
            end
            end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
           
            axH = polaraxes('parent',app.PatrondeRadiacinPanel);
            peak_clean = peak(1:512);
            
            % Normalización y gráfica como antes
            primervalor = peak_clean(1);
            datosNorm = peak_clean - primervalor;
            
            xoriginal = linspace(1, length(peak_clean), length(peak_clean));
            xobjetivo = linspace(1, length(peak_clean), 360);
            
            intepoldata = interp1(xoriginal, peak_clean, xobjetivo, 'linear');
            intepoldatanorm = interp1(xoriginal, datosNorm, xobjetivo, 'linear');
            
            app.transdata = intepoldata.';
            postransdata = abs(app.transdata);
            
            transdatanorm = intepoldatanorm.';
            postnorm = abs(intepoldatanorm);

            theta = linspace(0, 2*pi, 360);
            
            polarplot(axH,theta,intepoldata);
      
            app.NivelSealdBmEditField.Value = primervalor;
          

            nombre_antenna = 'Test_Antenna';
            frecuencia = 2300.0;
            ganancia = primervalor;
            horizontal = 360;

            if app.PlanoDropDown.Value == "Horizontal (E)"
                app.posdatanormH = postnorm.';
                app.H = intepoldata;
                columna_1 = (0:1:359)';


                % Abrir el archivo para escritura
                fileID = fopen('datos.pln', 'w');
    
                % Escribir el encabezado
                fprintf(fileID, 'NAME %s\n', nombre_antenna);
                fprintf(fileID, 'FREQUENCY %.1f\n', frecuencia);
                fprintf(fileID, 'GAIN %.2f dBd\n', ganancia);
                % Escribir la matriz con el formato deseado
                fprintf(fileID, 'HORIZONTAL %d\n', horizontal); % Salto de línea antes de los datos
                fprintf(fileID, '%.2f %.2f\n', [columna_1, app.posdatanormH]');
                fprintf(fileID, 'VERTICAL %d\n', horizontal);
                fprintf(fileID, '%.2f %.2f\n', [columna_1, zeros(360,1)]');
                fclose(fileID);

                [Horizontal,Vertical] = msiread('datos.pln');
               
                figure (1);
                P = polarpattern(Horizontal.Azimuth, Horizontal.Magnitude);
                P.TitleTop = 'MSI Planet file data';
                createLabels(P,'Plano Horizontal');
            else
            
            if app.PlanoDropDown.Value == "Vertical (H)"
                app.posdatanormV = postnorm.';
                app.V = intepoldata;
                columna_1 = (0:1:359)';


                % Abrir el archivo para escritura
                fileID = fopen('datos.pln', 'w');
    
                % Escribir el encabezado
                fprintf(fileID, 'NAME %s\n', nombre_antenna);
                fprintf(fileID, 'FREQUENCY %.1f\n', frecuencia);
                fprintf(fileID, 'GAIN %.2f dBd\n', ganancia);
                % Escribir la matriz con el formato deseado
                fprintf(fileID, 'HORIZONTAL %d\n', horizontal); % Salto de línea antes de los datos
                fprintf(fileID, '%.2f %.2f\n', [columna_1, zeros(360,1)]');
                fprintf(fileID, 'VERTICAL %d\n', horizontal);
                fprintf(fileID, '%.2f %.2f\n', [columna_1, app.posdatanormV]');
                fclose(fileID);

                [Horizontal,Vertical] = msiread('datos.pln');
                figure (2)
                P = polarpattern(Vertical.Elevation, Vertical.Magnitude);
                P.TitleTop = 'MSI Planet file data';
                createLabels(P,'Plano Vertical');
            end
            end


            if isempty(app.posdatanormH) || isempty(app.posdatanormV)
                app.Graf3DButton.Enable ="off";
            else
                app.Graf3DButton.Enable = "on";
            end

            app.IniciarMedicinButton.Enable = "on";
        end

        % Menu selected function: GuardarDatosSimMenu
        function GuardarDatosSimMenuSelected(app, event)

            fig = app.SistemadeMedicindeAntenaUIFigure;
            if isempty(app.transdata)
                uialert(fig,"No hay datos para guardar. Asegúrate de haber generado los datos primero.","Error", 'Icon','error');
                return;
            end

            if isempty(app.NombreAntenaDropDown.Value) || ...
               isempty(app.FrecuenciaMHzEditField.Value) || ...
               isempty(app.NivelSealdBmEditField.Value)
                uialert(fig, 'Por favor completa todos los campos antes de guardar.', 'Campos incompletos', 'Icon','warning');
                return;
            end

            if isempty(app.posdatanormV)
                nombre_antenna = app.NombreAntenaDropDown.Value;
                frecuencia = str2double(app.FrecuenciaMHzEditField.Value);
                ganancia = app.NivelSealdBmEditField.Value;
                horizontal = 360;
            
                % Generar datos (puedes cambiar esta parte por datos reales si los tienes)
                columna_1 = (0:359)';
            
                % Diálogo para guardar archivo
                [file, path] = uiputfile('*.pln', 'Guardar archivo .pln');
                if isequal(file,0)
                    return; % Usuario canceló
                end
            
                % Abrir archivo y escribir datos
                fileID = fopen(fullfile(path, file), 'w');
                fprintf(fileID, 'NAME %s\n', nombre_antenna);
                fprintf(fileID, 'FREQUENCY %.1f\n', frecuencia);
                fprintf(fileID, 'GAIN %.2f dBd\n', ganancia);
                fprintf(fileID, 'HORIZONTAL %d\n', horizontal);
                fprintf(fileID, '%.2f %.2f\n', [columna_1, app.posdatanormH]');
                fprintf(fileID, 'VERTICAL %d\n', horizontal);
                fprintf(fileID, '%.2f %.2f\n', [columna_1, zeros(360,1)]');
                fclose(fileID);
            
                uialert(fig, 'Solo se guardaran archivos en el plano Horizontal.', 'Plano', 'Icon','warning');
                uialert(fig, 'Archivo guardado correctamente.', 'Éxito', 'Icon','success');
                return;
            else

            if isempty(app.posdatanormH)
                nombre_antenna = app.NombreAntenaDropDown.Value;
                frecuencia = str2double(app.FrecuenciaMHzEditField.Value);
                ganancia = app.NivelSealdBmEditField.Value;
                horizontal = 360;
            
                % Generar datos (puedes cambiar esta parte por datos reales si los tienes)
                columna_1 = (0:359)';
            
                % Diálogo para guardar archivo
                [file, path] = uiputfile('*.pln', 'Guardar archivo .pln');
                if isequal(file,0)
                    return; % Usuario canceló
                end
            
                % Abrir archivo y escribir datos
                fileID = fopen(fullfile(path, file), 'w');
                fprintf(fileID, 'NAME %s\n', nombre_antenna);
                fprintf(fileID, 'FREQUENCY %.1f\n', frecuencia);
                fprintf(fileID, 'GAIN %.2f dBd\n', ganancia);
                fprintf(fileID, 'HORIZONTAL %d\n', horizontal);
                fprintf(fileID, '%.2f %.2f\n', [columna_1, zeros(360,1)]');
                fprintf(fileID, 'VERTICAL %d\n', horizontal);
                fprintf(fileID, '%.2f %.2f\n', [columna_1, app.posdatanormV]');
                fclose(fileID);
            
                uialert(fig, 'Solo se guardaran archivos en el plano Vertical.', 'Plano', 'Icon','warning');
                uialert(fig, 'Archivo guardado correctamente.', 'Éxito', 'Icon','success');
                return;
            else
          
            % nombre_antenna = app.NombreAntenaEditField.Value;
            nombre_antenna = app.NombreAntenaDropDown.Value;
            frecuencia = str2double(app.FrecuenciaMHzEditField.Value);
            ganancia = app.NivelSealdBmEditField.Value;
            horizontal = 360;
        
            % Generar datos (puedes cambiar esta parte por datos reales si los tienes)
            columna_1 = (0:359)';
        
            % Diálogo para guardar archivo
            [file, path] = uiputfile('*.pln', 'Guardar archivo .pln');
            if isequal(file,0)
                return; % Usuario canceló
            end
        
            % Abrir archivo y escribir datos
            fileID = fopen(fullfile(path, file), 'w');
            fprintf(fileID, 'NAME %s\n', nombre_antenna);
            fprintf(fileID, 'FREQUENCY %.1f\n', frecuencia);
            fprintf(fileID, 'GAIN %.2f dBd\n', ganancia);
            fprintf(fileID, 'HORIZONTAL %d\n', horizontal);
            fprintf(fileID, '%.2f %.2f\n', [columna_1, app.posdatanormH]');
            fprintf(fileID, 'VERTICAL %d\n', horizontal);
            fprintf(fileID, '%.2f %.2f\n', [columna_1, app.posdatanormV]');
            fclose(fileID);
        
            uialert(fig, 'Archivo guardado correctamente.', 'Éxito', 'Icon','success');
            end
            end
        end

        % Menu selected function: AbrirPatronRadiacionMenu
        function AbrirPatronRadiacionMenuSelected(app, event)
            fig = app.SistemadeMedicindeAntenaUIFigure;
            [file, path] = uigetfile('*.pln', 'Seleccionar archivo .pln');
            if isequal(file,0)
                return; % Usuario canceló
            end

            % Ruta completa del archivo
            filename = fullfile(path, file);

            % Leer con msiread
            try
                [Horizontal, Vertical] = msiread(filename);
                % Mostrar en gráfico polar
                figure (4);
                P = polarpattern(Horizontal.Azimuth, Horizontal.Magnitude);
                P.TitleTop = 'MSI Planet file data';
                createLabels(P, 'Plano Horizontal');
                figure (5);
                Pel = polarpattern(Vertical.Elevation, Vertical.Magnitude);
                Pel.TitleTop = 'MSI Planet file data';
                createLabels(Pel, 'Plano vertical');
               
                uialert(fig, 'Archivo cargado correctamente.', 'Listo', 'Icon','success');
            catch ME
                uialert(fig, ['Error al leer el archivo: ' ME.message], 'Error', 'Icon','error');
            end
        end

        % Menu selected function: ADALMPLUTOMenu
        function ADALMPLUTOMenuSelected(app, event)
            app.ADALMPLUTOMenu.Checked = "on";
            app.RTLSDRMenu.Checked = "off";
        end

        % Menu selected function: RTLSDRMenu
        function RTLSDRMenuSelected(app, event)
            app.ADALMPLUTOMenu.Checked = "off";
            app.RTLSDRMenu.Checked = "on";
        end

        % Close request function: SistemadeMedicindeAntenaUIFigure
        function SistemadeMedicindeAntenaUIFigureCloseRequest(app, event)
            figs = findall(0, 'Type', 'figure'); % Encuentra todas las figuras
            for i = 1:length(figs)
                if ~isequal(figs(i), app.SistemadeMedicindeAntenaUIFigure) % No cerrar la figura principal de la app
                    close(figs(i));
                end
            end
            close_system('transceiver/Spectrum Analyzer', 0);
            close_system('transceiver_RTL/Spectrum Analyzer', 0);
            delete(app)
        end

        % Button pushed function: Graf3DButton
        function Graf3DButtonPushed(app, event)
            nombre_antenna = 'Test_Antenna';
            frecuencia = 2300.0;
            ganancia = 23;
            horizontal = 360;
            columna_1 = (0:1:359)';

            fileID = fopen('datos.pln', 'w');
    
            % Escribir el encabezado
            fprintf(fileID, 'NAME %s\n', nombre_antenna);
            fprintf(fileID, 'FREQUENCY %.1f\n', frecuencia);
            fprintf(fileID, 'GAIN %.2f dBd\n', ganancia);
            % Escribir la matriz con el formato deseado
            fprintf(fileID, 'HORIZONTAL %d\n', horizontal); % Salto de línea antes de los datos
            fprintf(fileID, '%.2f %.2f\n', [columna_1, app.posdatanormH]');
            fprintf(fileID, 'VERTICAL %d\n', horizontal);
            fprintf(fileID, '%.2f %.2f\n', [columna_1, app.posdatanormV]');
            fclose(fileID);

            [Horizontal,Vertical] = msiread('datos.pln');
            %visualizar patron 3D
            figure (3); 
            vertSlice = Vertical.Magnitude;
            theta = 90-Vertical.Elevation;
            horizSlice = Horizontal.Magnitude;
            phi = Horizontal.Azimuth;
            patternFromSlices(vertSlice,theta,horizSlice,phi,Method="CrossWeighted");

        end

        % Menu selected function: AbrirPatronRadiacion3DMenu
        function AbrirPatronRadiacion3DMenuSelected(app, event)
            fig = app.SistemadeMedicindeAntenaUIFigure;
            [file, path] = uigetfile('*.pln', 'Seleccionar archivo .pln');
            if isequal(file,0)
                return; % Usuario canceló
            end
        
            % Ruta completa del archivo
            filename = fullfile(path, file);
        
            % Leer con msiread
            try
                [Horizontal, Vertical] = msiread(filename);
                % Mostrar en gráfico 3D
                figure (6);
                vertSlice = Vertical.Magnitude;
                theta = 90-Vertical.Elevation;
                horizSlice = Horizontal.Magnitude;
                phi = Horizontal.Azimuth;
                patternFromSlices(vertSlice,theta,horizSlice,phi,Method="CrossWeighted");
               
                uialert(fig, 'Archivo cargado correctamente.', 'Listo', 'Icon','success');
            catch ME
                uialert(fig, ['Error al leer el archivo: ' ME.message], 'Error', 'Icon','error');
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create SistemadeMedicindeAntenaUIFigure and hide until all components are created
            app.SistemadeMedicindeAntenaUIFigure = uifigure('Visible', 'off');
            app.SistemadeMedicindeAntenaUIFigure.Color = [0.302 0.7451 0.9333];
            app.SistemadeMedicindeAntenaUIFigure.Position = [350 200 842 480];
            app.SistemadeMedicindeAntenaUIFigure.Name = 'Sistema de Medición de Antena';
            app.SistemadeMedicindeAntenaUIFigure.Icon = fullfile(pathToMLAPP, 'Captura de pantalla 2025-04-15 200511.png');
            app.SistemadeMedicindeAntenaUIFigure.Resize = 'off';
            app.SistemadeMedicindeAntenaUIFigure.CloseRequestFcn = createCallbackFcn(app, @SistemadeMedicindeAntenaUIFigureCloseRequest, true);

            % Create ArchivoMenu
            app.ArchivoMenu = uimenu(app.SistemadeMedicindeAntenaUIFigure);
            app.ArchivoMenu.Text = 'Archivo';

            % Create AbrirPatronRadiacionMenu
            app.AbrirPatronRadiacionMenu = uimenu(app.ArchivoMenu);
            app.AbrirPatronRadiacionMenu.MenuSelectedFcn = createCallbackFcn(app, @AbrirPatronRadiacionMenuSelected, true);
            app.AbrirPatronRadiacionMenu.Text = 'Abrir Patron Radiacion';

            % Create AbrirPatronRadiacion3DMenu
            app.AbrirPatronRadiacion3DMenu = uimenu(app.ArchivoMenu);
            app.AbrirPatronRadiacion3DMenu.MenuSelectedFcn = createCallbackFcn(app, @AbrirPatronRadiacion3DMenuSelected, true);
            app.AbrirPatronRadiacion3DMenu.Text = 'Abrir Patron Radiacion 3D';

            % Create GuardarDatosSimMenu
            app.GuardarDatosSimMenu = uimenu(app.ArchivoMenu);
            app.GuardarDatosSimMenu.MenuSelectedFcn = createCallbackFcn(app, @GuardarDatosSimMenuSelected, true);
            app.GuardarDatosSimMenu.Text = 'Guardar Datos Sim.';

            % Create SimulacinMenu
            app.SimulacinMenu = uimenu(app.SistemadeMedicindeAntenaUIFigure);
            app.SimulacinMenu.Text = 'Simulación';

            % Create ADALMPLUTOMenu
            app.ADALMPLUTOMenu = uimenu(app.SimulacinMenu);
            app.ADALMPLUTOMenu.MenuSelectedFcn = createCallbackFcn(app, @ADALMPLUTOMenuSelected, true);
            app.ADALMPLUTOMenu.Tooltip = {'Este boton es para indicar que el radio ADALM PLUTO sera utilizado para la captura de datos'};
            app.ADALMPLUTOMenu.Checked = 'on';
            app.ADALMPLUTOMenu.Text = 'ADALM-PLUTO';

            % Create RTLSDRMenu
            app.RTLSDRMenu = uimenu(app.SimulacinMenu);
            app.RTLSDRMenu.MenuSelectedFcn = createCallbackFcn(app, @RTLSDRMenuSelected, true);
            app.RTLSDRMenu.Tooltip = {'Este boton es para indicar que el radio RTL-SDR sera utilizado para la '};
            app.RTLSDRMenu.Text = 'RTL-SDR';

            % Create IniciarMedicinButton
            app.IniciarMedicinButton = uibutton(app.SistemadeMedicindeAntenaUIFigure, 'push');
            app.IniciarMedicinButton.ButtonPushedFcn = createCallbackFcn(app, @IniciarMedicinButtonPushed, true);
            app.IniciarMedicinButton.FontWeight = 'bold';
            app.IniciarMedicinButton.Tooltip = {'Inicia la captura de datos '};
            app.IniciarMedicinButton.Position = [16 240 105 28];
            app.IniciarMedicinButton.Text = 'Iniciar Medición';

            % Create FrecuenciaMHzEditFieldLabel
            app.FrecuenciaMHzEditFieldLabel = uilabel(app.SistemadeMedicindeAntenaUIFigure);
            app.FrecuenciaMHzEditFieldLabel.HorizontalAlignment = 'right';
            app.FrecuenciaMHzEditFieldLabel.FontSize = 14;
            app.FrecuenciaMHzEditFieldLabel.FontWeight = 'bold';
            app.FrecuenciaMHzEditFieldLabel.Position = [18 396 121 22];
            app.FrecuenciaMHzEditFieldLabel.Text = 'Frecuencia (MHz)';

            % Create FrecuenciaMHzEditField
            app.FrecuenciaMHzEditField = uieditfield(app.SistemadeMedicindeAntenaUIFigure, 'text');
            app.FrecuenciaMHzEditField.Editable = 'off';
            app.FrecuenciaMHzEditField.HorizontalAlignment = 'right';
            app.FrecuenciaMHzEditField.Position = [154 396 123 22];

            % Create PatrondeRadiacinPanel
            app.PatrondeRadiacinPanel = uipanel(app.SistemadeMedicindeAntenaUIFigure);
            app.PatrondeRadiacinPanel.AutoResizeChildren = 'off';
            app.PatrondeRadiacinPanel.BorderColor = [0 0 0];
            app.PatrondeRadiacinPanel.HighlightColor = [0 0 0];
            app.PatrondeRadiacinPanel.BorderType = 'none';
            app.PatrondeRadiacinPanel.Title = 'Patron de Radiación';
            app.PatrondeRadiacinPanel.FontWeight = 'bold';
            app.PatrondeRadiacinPanel.FontSize = 14;
            app.PatrondeRadiacinPanel.Position = [338 1 505 480];

            % Create NivelSealdBmEditFieldLabel
            app.NivelSealdBmEditFieldLabel = uilabel(app.SistemadeMedicindeAntenaUIFigure);
            app.NivelSealdBmEditFieldLabel.HorizontalAlignment = 'right';
            app.NivelSealdBmEditFieldLabel.FontSize = 14;
            app.NivelSealdBmEditFieldLabel.FontWeight = 'bold';
            app.NivelSealdBmEditFieldLabel.Position = [18 358 121 22];
            app.NivelSealdBmEditFieldLabel.Text = 'Nivel Señal (dBm)';

            % Create NivelSealdBmEditField
            app.NivelSealdBmEditField = uieditfield(app.SistemadeMedicindeAntenaUIFigure, 'numeric');
            app.NivelSealdBmEditField.Editable = 'off';
            app.NivelSealdBmEditField.Position = [154 358 123 22];

            % Create NombreAntenaDropDownLabel
            app.NombreAntenaDropDownLabel = uilabel(app.SistemadeMedicindeAntenaUIFigure);
            app.NombreAntenaDropDownLabel.HorizontalAlignment = 'right';
            app.NombreAntenaDropDownLabel.FontSize = 14;
            app.NombreAntenaDropDownLabel.FontWeight = 'bold';
            app.NombreAntenaDropDownLabel.Position = [18 435 109 22];
            app.NombreAntenaDropDownLabel.Text = 'Nombre Antena';

            % Create NombreAntenaDropDown
            app.NombreAntenaDropDown = uidropdown(app.SistemadeMedicindeAntenaUIFigure);
            app.NombreAntenaDropDown.Items = {'Dipolo λ 1GHz', 'Dipolo λ/2', 'Dipolo λ', 'Parche', 'Yagi Uda'};
            app.NombreAntenaDropDown.FontWeight = 'bold';
            app.NombreAntenaDropDown.Position = [154 435 123 22];
            app.NombreAntenaDropDown.Value = 'Dipolo λ 1GHz';

            % Create PlanoDropDownLabel
            app.PlanoDropDownLabel = uilabel(app.SistemadeMedicindeAntenaUIFigure);
            app.PlanoDropDownLabel.FontSize = 14;
            app.PlanoDropDownLabel.FontWeight = 'bold';
            app.PlanoDropDownLabel.Position = [18 319 43 22];
            app.PlanoDropDownLabel.Text = 'Plano';

            % Create PlanoDropDown
            app.PlanoDropDown = uidropdown(app.SistemadeMedicindeAntenaUIFigure);
            app.PlanoDropDown.Items = {'Horizontal (E)', 'Vertical (H)'};
            app.PlanoDropDown.FontWeight = 'bold';
            app.PlanoDropDown.Position = [154 319 123 22];
            app.PlanoDropDown.Value = 'Horizontal (E)';

            % Create Graf3DButton
            app.Graf3DButton = uibutton(app.SistemadeMedicindeAntenaUIFigure, 'push');
            app.Graf3DButton.ButtonPushedFcn = createCallbackFcn(app, @Graf3DButtonPushed, true);
            app.Graf3DButton.FontWeight = 'bold';
            app.Graf3DButton.Enable = 'off';
            app.Graf3DButton.Tooltip = {'Se requiere capturar datos en ambos planos para generar patron 3D'};
            app.Graf3DButton.Position = [18 204 101 28];
            app.Graf3DButton.Text = 'Graf. 3D';

            % Show the figure after all components are created
            app.SistemadeMedicindeAntenaUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = AntennaMesuarementSystem_exported

            % Associate the Simulink Model
            app.Simulation = simulation('transceiver');

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.SistemadeMedicindeAntenaUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.SistemadeMedicindeAntenaUIFigure)
        end
    end
end