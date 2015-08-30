<?php

namespace Muni;

class Muni
{
	var $ch;

	function __construct()
	{
		$this->ch = curl_init();

		curl_setopt( $this->ch, CURLOPT_USERAGENT,'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/32.0.1700.107 Chrome/32.0.1700.107 Safari/537.36');
		curl_setopt( $this->ch, CURLOPT_SSL_VERIFYPEER, false);
		curl_setopt( $this->ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt( $this->ch, CURLOPT_COOKIESESSION, true);
		curl_setopt( $this->ch, CURLOPT_FOLLOWLOCATION, true);
		curl_setopt( $this->ch, CURLOPT_COOKIEJAR, '');  //could be empty, but cause problems on some hosts
		curl_setopt( $this->ch, CURLOPT_COOKIEFILE, '');  //could be empty, but cause problems on some hosts
	}


	/**
	 * Sends CURL request, returns HTML response.
	 *
	 * @param {string} url - url to be fetched
	 * @param {string} post - POST data in url encoded format
	 * @return {string} HTML response
	 */
	function get_page( $url, $post = '' )
	{
		curl_setopt( $this->ch, CURLOPT_URL, $url );
		curl_setopt( $this->ch, CURLOPT_POST, ! empty( $post ) );
		curl_setopt( $this->ch, CURLOPT_POSTFIELDS, $post );

		return curl_exec( $this->ch );
	}


	/**
	 * Signs in user, then redirects to specified page.
	 *
	 * @param {string} username - UČO
	 * @param {string} password - password
	 * @param {string} destination - redirection after successful signing in
	 * @return {string} HTML response
	 */
	function sign_in( $username, $password, $destination )
	{
		return $this->get_page( 'https://is.muni.cz/system/login_form.pl', sprintf( "credential_0=%s&credential_1=%s&credential_2=3600&destination=%s", $username, $password, $destination ));		
	}


	/**
	 * Gets details about class
	 *
	 * @param {string} faculty - code of faculty, e.g. fi
	 * @param {string} code - code of class, e.g. MB101
	 * @return {string} HTML response
	 */
	 
	function read_class( $faculty, $code )
	{
		$response = $this->get_page( sprintf( 'https://is.muni.cz/auth/predmet/%s/%s/%s', $faculty, SEMESTER_NAME, $code) );

		preg_match('#<A HREF="(.+?)">Úplný výpis informací o předmětu</A>#', $response, $matches );
		if ( count( $matches ) == 0 ) throw new \Exception( sprintf( 'Predmet s kódom [%s] som nenašiel.', $code ) );

		preg_match( '#uplny_vypis\?(.+)#', $matches[1], $args );
		if (  count( $args ) == 0 ) throw new \Exception( sprintf( 'Predmet s kódom [%s] som nenašiel.', $code ) );

		return $this->get_page('https://is.muni.cz' . trim($matches[1]), str_replace( ';', '&', $args[1] ));
	}

	/**
	 * Returns data of given classes
	 *
	 * @param {string} classes - comma separated list of classes, e.g. 'FI:MB103, FI:MB102'
	 * @return {array} - parsed classes data
	 */
	function read_classes( $classes )
	{
		$params = explode( ',', $classes );
		$output = [ 'classes' => [], 'errors' => [] ];

		// fi, econ, phil

		foreach ( $params as $param )
		{
			$response = new \stdClass();

			try
			{
				$class = explode( ':', trim( $param ) );

				if ( count( $class ) != 2 ) throw new \Exception( sprintf('Predmet [%s] zadaný v nesprávnom tvare!', $param ));

				$faculty = $this->_get_faculty( strtolower( trim( $class[0] )));
				$class_code = strtoupper( trim( $class[1] ));

				$site = $this->read_class( $faculty, $class_code );

				$response->code = $class_code;
				$response->name = \Filter\read_table_value( $site, 'Název' );
				$response->lecture = ( \Filter\read_table_value( $site, 'Rozvrhové informace' ) != 'nezadány' ) ? \Filter\read_lecture( $site, $class_code ) : NULL;
				$response->labs = ( \Filter\read_table_value( $site, 'Členění na seminární/paralelní výuku') != 'žádné seminární skupiny' ) ? \Filter\read_classes( $site, $class_code ) : array();
				$response->permalink = sprintf( 'https://is.muni.cz/auth/predmet/%s/%s/%s', $faculty, SEMESTER_NAME, $class_code); # TODO: presunúť do funkcie
				$response->timestamp = time();

				array_push( $output['classes'], $response );

			}

			catch ( \Exception $e )
			{
				array_push( $output['errors'], $e->getMessage() );
			}
		}

		return $output;
	}

	/**
	 * Converts faculty code used with subjects into another faculty code used in subject details :D
	 *
	 * @param {string} code - faculty code
	 * @return {string} - another faculty code
	 */
	function _get_faculty( $code )
	{
		$fac = array( 'fi' => 'fi', 'esf' => 'econ', 'ff' => 'phil', 'lf' => 'med', 'prf' => 'law', 'fss' => 'fss', 'přf' => 'sci', 'fsps' => 'fsps', 'pdf' => 'ped' );
		return $fac[ $code ];
	}
}