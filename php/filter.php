<?php

namespace Filter;

function read_table_value( $source, $key, $filter = TRUE )
{
	if ( empty( $source ) || empty( $key ) ) throw new \Exception( 'Argumenty v nesprávnom tvare!' );


	preg_match( sprintf( '#<TR VALIGN=top><TD>.*?%s.*?</TD><TD>(.+?)</TD></TR>#i', $key), $source, $results );

	return ( ! empty( $results[1] ) ) ? preg_replace( '#<.+?>#', '', $results[1] ) : FALSE;
}


function read_lecture( $source, $code )
{
	if ( empty( $source ) || empty( $code ) ) throw new \Exception( 'Argumenty v nesprávnom tvare!' );


	preg_match('#^(Po|Út|St|Čt|Pá|každ.+) ([0-9]{1,2}):([0-9]{1,2})[\–-]{1,2}([0-9]{1,2}):([0-9]{1,2}) ([^,]+)#', read_table_value( $source, 'Rozvrhové informace' ), $results);


	if ( count( $results ) > 0 )
	{
		$note = '';

		$day = get_day( $results[1] );
		if ( ! empty( $day[1] ) ) $note .= $day[1] . ' | ';

		return [

			'code' => $code,
			'name' => read_table_value( $source, 'Název' ),
			'day'  => $day[0],
			'time' => [ 'from' => get_time( $results[2], $results[3] ), 'to' => get_time( $results[4], $results[5] ) ],
			'room' => $results[6],
			'note' => $note
		];
	}

	return FALSE;
}


function read_classes( $source, $code )
{
	if ( empty( $source ) || empty( $code ) ) throw new \Exception( 'Argumenty v nesprávnom tvare!' );


	preg_match_all('#<div class="seminar"><h5>(.+?)</h5>(.+?)<a .+?>(.+?)</a>.+?(Vyučující:&nbsp;<a href="/auth/osoba/(.+?)">(.+?)</a>.+?)?(<span.+?</span>)?(Poznámka: (.+?))?<br style="margin-bottom: -0.70em;" />.+?</div>#is', $source, $results);

	/*
		1 - kód skupiny
		2 - časy
		3 - kde
		4 - vyucujuci + zmeneno
		5 - vyucujuci link
		6 - vyucujuci meno
		7 - ?
		8 - poznamka
		9 - poznamka obsah
	*/

	$classes = [];

	for ( $i = 0; $i < count( $results[0] ); $i++ )
	{
		$note = '';

		preg_match( '#(Po|Út|St|Čt|Pá|každ.+) ([0-9]{1,2}):([0-9]{1,2})–([0-9]{1,2}):([0-9]{1,2})#', $results[2][$i], $date );


		# Overíme, či sme zanalyzovali celý dátum, ak nie pripíšeme poznámku

		if ( trim( $date[0] ) != trim( $results[2][$i] )) $note .= trim( $results[2][$i] ) . ' | ';


		# Ak je to 'každé sudé' a podobne, napíšeme poznámku

		$day = get_day( $date[1] );

		if ( ! empty( $day[1] ) ) $note .= $day[1] . ' | ';

		array_push( $classes, [

			'subject' => $code,
			'code' => $results[1][$i],
			'day' => $day[0],
			'time' => [ 'from' => get_time( $date[2], $date[3] ), 'to' => get_time( $date[4], $date[5] ) ],
			'room' => $results[3][$i],
			'teacher' => [ 'name' => trim( $results[6][$i] ), 'link' => trim( $results[5][$i] ) ],
			'note' => trim( $note . preg_replace( '#<.+?>#', '', $results[9][$i] ))
		]);
	}

	return $classes;
}


function get_day( $day )
{
	$days = [ 'Po', 'Út', 'St', 'Čt', 'Pá' ];
	$note = NULL;

	preg_match( '#(po|út|st|čt|pá)#i', $day, $results );

	if ( array_search( trim($day), $days ) === FALSE && count( $results ) > 0 )
	{
		$results[1] = str_replace( 'po', 'Po' , $results[1] );
		$results[1] = str_replace( 'út', 'Út' , $results[1] );
		$results[1] = str_replace( 'čt', 'Čt' , $results[1] );
		$results[1] = str_replace( 'st', 'St' , $results[1] );
		$results[1] = str_replace( 'pá', 'Pá' , $results[1] );
		
		$note = $day;
		$day = $results[1];
	}

	return [ array_search( trim($day), $days ), $note ];
}


function get_time( $hour, $minute )
{
	return $hour . ( $minute == '00' ? '00' : ( round( ($minute / 60) * 100 ) < 10 ? '0': '' ) . ( round( ($minute / 60) * 100 ) ));
}


function read_registred( $site )
{
	preg_match_all( '#<TR class="predm_hlavni" VALIGN=top><TD><B><A HREF=".+?" target="_blank" class="okno">(.+?)</A></B>#i', $site, $results);

	return ( count( $results ) > 0 ) ? $results[1] : FALSE;
}