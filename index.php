<?php

require 'php/muni.php';
require 'php/filter.php';

define( 'SEMESTER_NAME', 'podzim2015' );
define( 'SEMESTER_CODE', '6383' );

session_start();

error_reporting(0);

if ( ! empty( $_POST ) )
{
	$muni = new Muni\Muni();

	try
	{
		switch ( $_POST['action'] )
		{
			case 'sign_in':

				# Máme potrebné údaje?

				if ( empty( $_POST['uco'] ) || empty( $_POST['password'] ) ) throw new Exception( 'Chýbajú povinné údaje' );

				
				# Skúsime sa prihlásiť na MUNI

				$response = $muni->sign_in( trim( $_POST['uco'] ), $_POST['password'], '/auth/student/zapis.pl?obdobi=' . SEMESTER_CODE );


				# Pokiaľ odpoveď obsahuje možnosť 'Registrace/zápis predmetu', tak sme sa prihlásili, inak by sme videli opäť prihlasovací formulár

				if ( preg_match('#<h1 id="nadpis">Registrace/zápis předmětů</h1>#i', $response ))
				{

					# Uložíme si UČO a heslo pre ďalšie dopyty

					$_SESSION['uco'] = $_POST['uco'];
					$_SESSION['password'] = $_POST['password'];


					# Ak už má v prehliadači uložený rozvrh človek s rovnakým UČOm, tak ho len dostaneme do prehliadača, nič nenačítavame,
					# inak parsujeme MUNI 

					if ( $_POST['person'] != $_POST['uco'] )
					{
						$classes = Filter\read_registred( $response, SEMESTER_CODE ); ## TODO: vyratavať obdobi nejako rozumnejšie		

						if ( $classes )
						{
							$output = $muni->read_classes( join( ',', $classes) );
						}

						else
						{
							throw new Exception( 'Žiadne registrované predmety' );
						}
					}

					else
					{
						$output->log_me_in = true;
					}
				}


				else
				{
					throw new Exception( 'Nesprávne UČO/heslo!' );
				}

				break;


			case 'read':


				# Skontrolujeme, či máme povinné údaje

				if ( empty( $_SESSION['uco'] ) ) throw new Exception( 'Neprihlásený!' );
				if ( empty( $_POST['classes'] ) ) throw new Exception( 'Chýbajú povinné údaje!' );


				$muni->sign_in( $_SESSION['uco'], $_SESSION['password'], '/auth/' );
				$output = $muni->read_classes( $_POST['classes'] );

				break;


			case 'sign_out':

				session_destroy();
				break;
		}

	}

	catch ( Exception $e )
	{
		array_push( $output->errors, $e->getMessage() );
	}

	echo json_encode( $output );
}

else
{
	require ( empty( $_SESSION['uco'] )) ? 'sign_in.html' : 'schedule.html';
}