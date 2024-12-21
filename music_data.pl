use strict;
use warnings;

use Term::Menus;
use Term::ANSIColor;

print "Opening the CSV file...\n";
# Use a relative path to open the file
my $file_path = "topspotify.csv";

open my $fh, '<', $file_path or die "Could not open '$file_path': $!";


#Storing the data
my %songsByYear;        #Songs by Year (e.g., 2010 => song...)
my %songsByGenre;       #Songs by Genre
my %artistsByYear;      #Artists by Year
my %genresPopularity;   #Popularity by genre
my %energyLevels;       #Energy levels for songs
my %acousticness;       #Acousticness levels by year
my %bpmByGenre;         #BPM by genre
my %danceability;       #Songs by danceability
my %soloArtistsByYear;  #Solo artists by year
my %duoArtistsByYear;   #Duo artists by year
my %groupArtistsByYear; #Group artists by year

my %artistSongCount;  #Artist song count

print "Processing the data from the CSV file...\n";
while (my $line = <$fh>) {
    chomp $line;
    my @str = split /,/, $line;

    #Skip rows with missing data
    next if scalar(@str) < 17;

    # Assign variables for better readability
    my $title    = $str[0];    #Song title
    my $artist   = $str[1];    #Artist
    my $genre    = $str[2];    #Top genre
    my $year     = $str[3];    #Year released
    my $bpm      = $str[5];    #Beats per minute
    my $energy   = $str[6];    #Energy level
    my $dance    = $str[7];    #Danceability
    my $acoustic = $str[12];   #Acousticness
    my $pop      = $str[14];   #Popularity
    my $solo     = $str[16];   #Solo or group

    #Accumulate data for different categories
    push @{ $songsByYear{$year} }, { title => $title, artist => $artist, genre => $genre, pop => $pop, energy => $energy, acoustic => $acoustic, bpm => $bpm, dance => $dance };
    push @{ $songsByGenre{$genre} }, { title => $title, artist => $artist, pop => $pop, bpm => $bpm };

    $genresPopularity{$genre} += $pop;
    $bpmByGenre{$genre}{total} += $bpm;
    $bpmByGenre{$genre}{count}++;
    push @{ $energyLevels{$energy} }, { title => $title, artist => $artist };
    push @{ $acousticness{$year} }, { title => $title, artist => $artist, acoustic => $acoustic };
    $artistSongCount{$artist}++;

    if ($solo =~ /Solo/i) {
    push @{ $soloArtistsByYear{$year} }, { artist => $artist, pop => $pop };
} elsif ($solo =~ /Duo/i) {
    push @{ $duoArtistsByYear{$year} }, { artist => $artist, pop => $pop };
} elsif ($solo =~ /Band\/Group/i) {
    push @{ $groupArtistsByYear{$year} }, { artist => $artist, pop => $pop };
}
}

close $fh;
print "Data processing complete.\n";

#Helper functions
sub top_artists_by_year {
    my ($year, $n) = @_;
    my %artist_popularity;

    for my $song (@{ $songsByYear{$year} }) {
        $artist_popularity{$song->{artist}} += $song->{pop};
    }

    my @sorted_artists = sort { $artist_popularity{$b} <=> $artist_popularity{$a} } keys %artist_popularity;
    return @sorted_artists[0..($n-1)];
}

sub top_songs_by_year {
    my ($year, $n) = @_;
    my @sorted_songs = sort { $b->{pop} <=> $a->{pop} } @{ $songsByYear{$year} };
    return @sorted_songs[0..($n-1)];
}

sub song_with_lowest_popularity_by_year {
    my ($year) = @_;
    my @sorted_songs = sort { $a->{pop} <=> $b->{pop} } @{ $songsByYear{$year} };
    return $sorted_songs[0];
}

sub average_bpm_by_genre {
    my %average_bpm;
    foreach my $genre (keys %bpmByGenre) {
        $average_bpm{$genre} = $bpmByGenre{$genre}{total} / $bpmByGenre{$genre}{count};
    }
    return %average_bpm;
}

sub most_popular_solo_artists_by_year {
    my ($year, $n) = @_;
    my @sorted_artists = sort { $b->{pop} <=> $a->{pop} } @{ $soloArtistsByYear{$year} };
    return @sorted_artists[0..($n-1)];
}

sub top_solo_artists_of_all_time {
    my ($n) = @_;
    
    my @all_artists;
    
    for my $year (keys %soloArtistsByYear) {
        push @all_artists, @{ $soloArtistsByYear{$year} };
    }

    my @sorted_artists = sort { $b->{pop} <=> $a->{pop} } @all_artists;

    return @sorted_artists[0..($n-1)];
}


#Function for most popular duo artists by year
sub most_popular_duo_artists_by_year {
    my ($year, $n) = @_;
    my @sorted_artists = sort { $b->{pop} <=> $a->{pop} } @{ $duoArtistsByYear{$year} };
    return @sorted_artists[0..($n-1)];
}

#Function for most popular group artists by year
sub most_popular_group_artists_by_year {
    my ($year, $n) = @_;
    my @sorted_artists = sort { $b->{pop} <=> $a->{pop} } @{ $groupArtistsByYear{$year} };
    return @sorted_artists[0..($n-1)];
}

sub most_popular_artist_per_genre_by_year {
    my ($year) = @_;
    my %artist_by_genre;

    foreach my $song (@{ $songsByYear{$year} }) {
        my $genre  = $song->{genre};
        my $artist = $song->{artist};
        $artist_by_genre{$genre}{$artist} += $song->{pop};
    }

    my %most_popular;
    foreach my $genre (keys %artist_by_genre) {
        my @sorted_artists = sort { $artist_by_genre{$genre}{$b} <=> $artist_by_genre{$genre}{$a} } keys %{ $artist_by_genre{$genre} };
        $most_popular{$genre} = $sorted_artists[0];
    }
    return %most_popular;
}

sub most_acoustic_songs_by_year {
    my ($year, $n) = @_;
    my @sorted_songs = sort { $b->{acoustic} <=> $a->{acoustic} } @{ $acousticness{$year} };
    return @sorted_songs[0..($n-1)];
}

sub top_energetic_songs {
    my ($n) = @_;
    my @sorted_songs = sort { $b->{energy} <=> $a->{energy} } map { @$_ } values %songsByYear;
    return @sorted_songs[0..($n-1)];
}

sub least_energetic_songs {
    my ($n) = @_;
    my @sorted_songs = sort { $a->{energy} <=> $b->{energy} } map { @$_ } values %songsByYear;
    return @sorted_songs[0..($n-1)];
}

sub top_duo_artists_of_all_time {
    my ($n) = @_;
    
    my @all_duo_artists;
    

    for my $year (keys %duoArtistsByYear) {
        push @all_duo_artists, @{ $duoArtistsByYear{$year} };
    }


    my @sorted_duo_artists = sort { $b->{pop} <=> $a->{pop} } @all_duo_artists;

    #Return the top N duo artists
    return @sorted_duo_artists[0..($n-1)];
}


#Menu options
my @menu = (
    "Top Artist by Year",
    "10 Top Songs by Year",
    "Song with Lowest Popularity by Year",
    "Average BPM by Genre",
    "5 Most Popular Solo Artists by Year",
    "5 Most Popular Duo Artists by Year",
    "Top 5 Solo Artists of All Time",
    "Most Popular Artist per Genre for a Specific Year",
    "Top 10 Most Energetic Songs",
    "10 Least Energetic Songs",
    "10 Most Acoustic Songs per Year",
    "Top 5 Duo Artists of All Time",
    "Exit"
);

# Wrap menu options with ANSI color for red
my @colored_menu = map { colored($_, 'red') } @menu;

# Menu (interaction)
while (1) {
    my $selection = pick(\@colored_menu, "Select an option for 2010-2020 Music:");

    # Remove color codes for matching
    $selection =~ s/\e\[.*?m//g;

    if ($selection eq "Top Artist by Year") {
        print "Enter a year (from 2010-2020): ";
        chomp(my $year = <STDIN>);
        my @top_artist = top_artists_by_year($year, 1);
        print "Top artist for $year: $top_artist[0]\n";

    } elsif ($selection eq "10 Top Songs by Year") {
        print "Enter a year (from 2010-2020): ";
        chomp(my $year = <STDIN>);
        my @top_songs = top_songs_by_year($year, 10);
        print "Top songs for $year:\n", join("\n", map { "$_->{title} by $_->{artist}" } @top_songs), "\n";

    } elsif ($selection eq "Song with Lowest Popularity by Year") {
        print "Enter a year (from 2010-2020): ";
        chomp(my $year = <STDIN>);
        my $lowest_song = song_with_lowest_popularity_by_year($year);
        print "Lowest popularity song for $year: $lowest_song->{title} by $lowest_song->{artist}\n";

    } elsif ($selection eq "Average BPM by Genre") {
        my %avg_bpm = average_bpm_by_genre();
        print "Average BPM by Genre:\n";
        foreach my $genre (keys %avg_bpm) {
            print "$genre: $avg_bpm{$genre}\n";
        }

   } elsif ($selection eq "5 Most Popular Solo Artists by Year") {
    print "Enter a year (from 2010-2020): ";
    chomp(my $year = <STDIN>);
    my @popular_solo_artists = most_popular_solo_artists_by_year($year, 5);
    print "Most popular solo artists for $year:\n", join("\n", map { $_->{artist} } @popular_solo_artists), "\n";

    } elsif ($selection eq "5 Most Popular Duo Artists by Year") {
    print "Enter a year (from 2010-2020): ";
    chomp(my $year = <STDIN>);
    my @popular_duo_artists = most_popular_duo_artists_by_year($year, 5);
    print "Most popular duo artists for $year:\n", join("\n", map { $_->{artist} } @popular_duo_artists), "\n";

   } elsif ($selection eq "Top 5 Solo Artists of All Time") {
    my @top_solo_artists = top_solo_artists_of_all_time(5);  
    print "Top Solo Artists of All Time:\n", join("\n", map { $_->{artist} } @top_solo_artists), "\n";
    
    }elsif ($selection eq "Most Popular Artist per Genre for a Specific Year") {
        print "Enter a year (from 2010-2020): ";
        chomp(my $year = <STDIN>);
        my %popular_artist_by_genre = most_popular_artist_per_genre_by_year($year);
        print "Most popular artist per genre for $year:\n";
        foreach my $genre (keys %popular_artist_by_genre) {
            print "$genre: $popular_artist_by_genre{$genre}\n";
        }

    } elsif ($selection eq "Top 10 Most Energetic Songs") {
        my @energetic_songs = top_energetic_songs(10);
        print "Top 10 most energetic songs:\n", join("\n", map { "$_->{title} by $_->{artist}" } @energetic_songs), "\n";

    } elsif ($selection eq "10 Least Energetic Songs") {
        my @least_energetic_songs = least_energetic_songs(10);
        print "10 least energetic songs:\n", join("\n", map { "$_->{title} by $_->{artist}" } @least_energetic_songs), "\n";

    } elsif ($selection eq "10 Most Acoustic Songs per Year") {
        print "Enter a year (from 2010-2020): ";
        chomp(my $year = <STDIN>);
        my @acoustic_songs = most_acoustic_songs_by_year($year, 10);
        print "Most acoustic songs for $year:\n", join("\n", map { "$_->{title} by $_->{artist}" } @acoustic_songs), "\n";

    } elsif ($selection eq "Top 5 Duo Artists of All Time") {
    my @top_duo_artists = top_duo_artists_of_all_time(5);  # Get top 5 duo artists of all time
    print "Top Duo Artists of All Time:\n", join("\n", map { $_->{artist} } @top_duo_artists), "\n";
    }

    elsif ($selection eq "Exit") {
        last;
    } else {
        print "Invalid selection. Try again.\n";
    }
}