#!/usr/bin/perl

##############################################################################
# FormMail                        Version 1.9                                #
# Copyright 1995-2001 Matt Wright mattw@worldwidemart.com                    #
# Created 06/09/95                Last Modified 08/03/01                     #
# Matt's Script Archive, Inc.:    http://www.worldwidemart.com/scripts/      #
##############################################################################

$mailprog = '/usr/lib/sendmail';

@referers = ('dominio.com');

@recipients = ('^jmaciasc0117@outlook.com');

@valid_ENV = ('REMOTE_HOST','REMOTE_ADDR','REMOTE_USER','HTTP_USER_AGENT');

&check_url;

&get_date;

&parse_form;

&check_required;

&send_mail;

&return_html;

sub check_url {

    local($check_referer) = 0;

    if ($ENV{'HTTP_REFERER'}) {
        foreach $referer (@referers) {
            if ($ENV{'HTTP_REFERER'} =~ m|https?://([^/]*)$referer|i) {
                $check_referer = 1;
                last;
            }
        }
    }
    else {
        $check_referer = 1;
    }

    if ($check_referer != 1) { &error('bad_referer') }
}

sub get_date {

    @days   = ('Sunday','Monday','Tuesday','Wednesday',
               'Thursday','Friday','Saturday');
    @months = ('January','February','March','April','May','June','July',
	         'August','September','October','November','December');

    ($sec,$min,$hour,$mday,$mon,$year,$wday) = (localtime(time))[0,1,2,3,4,5,6];
    $time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
    $year += 1900;

    $date = "$days[$wday], $months[$mon] $mday, $year at $time";

}

sub parse_form {

    %Config = ('recipient','',          'subject','',
               'email','',              'realname','',
               'redirect','',           'bgcolor','',
               'background','',         'link_color','',
               'vlink_color','',        'text_color','',
               'alink_color','',        'title','',
               'sort','',               'print_config','',
               'required','',           'env_report','',
               'return_link_title','',  'return_link_url','',
               'print_blank_fields','', 'missing_fields_redirect','');

    if ($ENV{'REQUEST_METHOD'} eq 'GET') {
        @pairs = split(/&/, $ENV{'QUERY_STRING'});
    }
    elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
 
        @pairs = split(/&/, $buffer);
    }
    else {
        &error('request_method');
    }

    foreach $pair (@pairs) {

        local($name, $value) = split(/=/, $pair);
 
        $name =~ tr/+/ /;
        $name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

        $value =~ s/<!--(.|\n)*-->//g;

        if (defined($Config{$name})) {
            $Config{$name} = $value;
        }
        else {
            if ($Form{$name} && $value) {
                $Form{$name} = "$Form{$name}, $value";
            }
            elsif ($value) {
                push(@Field_Order,$name);
                $Form{$name} = $value;
            }
        }
    }

    $Config{'required'} =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
    $Config{'required'} =~ s/(\s+)?\n+(\s+)?//g;
    $Config{'env_report'} =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
    $Config{'env_report'} =~ s/(\s+)?\n+(\s+)?//g;
    $Config{'print_config'} =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
    $Config{'print_config'} =~ s/(\s+)?\n+(\s+)?//g;

    @Required = split(/,/,$Config{'required'});
    @Env_Report = split(/,/,$Config{'env_report'});
    @Print_Config = split(/,/,$Config{'print_config'});

    foreach $env_item (@Env_Report) {
        foreach $valid_item (@valid_ENV) {
            if ( $env_item eq $valid_item ) { push(@temp_array, $env_item) }
        }
    } 
    @Env_Report = @temp_array;
}

sub check_required {

    local($require, @error);

    if ($Config{'subject'} =~ /(\n|\r)/m || 
        $Config{'recipient'} =~ /(\n|\r)/m) {
        &error('no_recipient');
    }

    if (!$Config{'recipient'}) {
        if (!defined(%Form)) { &error('bad_referer') }
        else                 { &error('no_recipient') }
    }
    else {

        $valid_recipient = 0;
        foreach $send_to (split(/,/,$Config{'recipient'})) {
            foreach $recipient (@recipients) {
                if ($send_to =~ /$recipient$/i) {
                    push(@send_to,$send_to); last;
                }
            }
        }
        if ($#send_to < 0) { &error('no_recipient') }
        $Config{'recipient'} = join(',',@send_to);
    }

    foreach $require (@Required) {

        if ($require eq 'email' && !&check_email($Config{$require})) {
            push(@error,$require);
        }

        elsif (defined($Config{$require})) {
            if (!$Config{$require}) {
                push(@error,$require);
            }
        }

        elsif (!$Form{$require}) {
            push(@error,$require);
        }
    }

    if (@error) { &error('missing_fields', @error) }
}

sub return_html {
    local($key,$sort_order,$sorted_field);

    if ($Config{'redirect'}) {
        print "Location: $Config{'redirect'}\n\n";
    }

    else {

        print "Content-type: text/html\n\n";
        print "<html>\n <head>\n";

        if ($Config{'title'}) { print "  <title>$Config{'title'}</title>\n" }
        else                  { print "  <title>Thank You</title>\n"        }

        print " </head>\n <body";

        &body_attributes;

        print ">\n  <center>\n";

        if ($Config{'title'}) { print "   <h1>$Config{'title'}</h1>\n" }
        else { print "   <h1>Thank You For Filling Out This Form</h1>\n" }

        print "</center>\n";

        print "Below is what you submitted to $Config{'recipient'} on ";
        print "$date<p><hr size=1 width=75\%><p>\n";

        if ($Config{'sort'} eq 'alphabetic') {
            foreach $field (sort keys %Form) {

                if ($Config{'print_blank_fields'} || $Form{$field}) {
                    print "<b>$field:</b> $Form{$field}<p>\n";
                }
            }
        }

        elsif ($Config{'sort'} =~ /^order:.*,.*/) {

            $sort_order = $Config{'sort'};
            $sort_order =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
            $sort_order =~ s/(\s+)?\n+(\s+)?//g;
            $sort_order =~ s/order://;
            @sorted_fields = split(/,/, $sort_order);

            foreach $sorted_field (@sorted_fields) {
                if ($Config{'print_blank_fields'} || $Form{$sorted_field}) {
                    print "<b>$sorted_field:</b> $Form{$sorted_field}<p>\n";
                }
            }
        }

        else {

            foreach $field (@Field_Order) {
                if ($Config{'print_blank_fields'} || $Form{$field}) {
                    print "<b>$field:</b> $Form{$field}<p>\n";
                }
            }
        }

        print "<p><hr size=1 width=75%><p>\n";


        if ($Config{'return_link_url'} && $Config{'return_link_title'}) {
            print "<ul>\n";
            print "<li><a href=\"$Config{'return_link_url'}\">$Config{'return_link_title'}</a>\n";
            print "</ul>\n";
        }

        print <<"(END HTML FOOTER)";
        <hr size=1 width=75%><p> 
        <center><font size=-1><a href="http://www.worldwidemart.com/scripts/formmail.shtml">FormMail</a> V1.9 &copy; 1995 - 2001  Matt Wright<br>
A Free Product of <a href="http://www.worldwidemart.com/scripts/">Matt's Script Archive, Inc.</a></font></center>
        </body>
       </html>
(END HTML FOOTER)
    }
}

sub send_mail {
    local($print_config,$key,$sort_order,$sorted_field,$env_report);

    open(MAIL,"|$mailprog -t");

    print MAIL "To: $Config{'recipient'}\n";
    print MAIL "From: $Config{'email'} ($Config{'realname'})\n";

    if ($Config{'subject'}) { print MAIL "Subject: $Config{'subject'}\n\n" }
    else                    { print MAIL "Subject: WWW Form Submission\n\n" }

    print MAIL "Below is the result of your feedback form.  It was submitted by\n";
    print MAIL "$Config{'realname'} ($Config{'email'}) on $date\n";
    print MAIL "-" x 75 . "\n\n";

    if (@Print_Config) {
        foreach $print_config (@Print_Config) {
            if ($Config{$print_config}) {
                print MAIL "$print_config: $Config{$print_config}\n\n";
            }
        }
    }

    if ($Config{'sort'} eq 'alphabetic') {
        foreach $field (sort keys %Form) {

            if ($Config{'print_blank_fields'} || $Form{$field} ||
                $Form{$field} eq '0') {
                print MAIL "$field: $Form{$field}\n\n";
            }
        }
    }

    elsif ($Config{'sort'} =~ /^order:.*,.*/) {

        $Config{'sort'} =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
        $Config{'sort'} =~ s/(\s+)?\n+(\s+)?//g;
        $Config{'sort'} =~ s/order://;
        @sorted_fields = split(/,/, $Config{'sort'});

        foreach $sorted_field (@sorted_fields) {
            if ($Config{'print_blank_fields'} || $Form{$sorted_field} ||
                $Form{$sorted_field} eq '0') {
                print MAIL "$sorted_field: $Form{$sorted_field}\n\n";
            }
        }
    }

    else {

        foreach $field (@Field_Order) {
            if ($Config{'print_blank_fields'} || $Form{$field} ||
                $Form{$field} eq '0') {
                print MAIL "$field: $Form{$field}\n\n";
            }
        }
    }

    print MAIL "-" x 75 . "\n\n";

    foreach $env_report (@Env_Report) {
        if ($ENV{$env_report}) {
            print MAIL "$env_report: $ENV{$env_report}\n";
        }
    }

    close (MAIL);
}

sub check_email {
    $email = $_[0];

    if ($email =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||

        $email !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z0-9]+)(\]?)$/) {

        return 0;
    }

    else {

        return 1;
    }
}

sub body_attributes {
    if ($Config{'bgcolor'}) { print " bgcolor=\"$Config{'bgcolor'}\"" }

    if ($Config{'background'}) { print " background=\"$Config{'background'}\"" }

    if ($Config{'link_color'}) { print " link=\"$Config{'link_color'}\"" }

    if ($Config{'vlink_color'}) { print " vlink=\"$Config{'vlink_color'}\"" }

    if ($Config{'alink_color'}) { print " alink=\"$Config{'alink_color'}\"" }

    if ($Config{'text_color'}) { print " text=\"$Config{'text_color'}\"" }
}

sub error { 
    local($error,@error_fields) = @_;
    local($host,$missing_field,$missing_field_list);

    if ($error eq 'bad_referer') {
        if ($ENV{'HTTP_REFERER'} =~ m|^https?://([\w\.]+)|i) {
            $host = $1;
            print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Bad Referrer - Access Denied</title>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>Bad Referrer - Access Denied</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>The form attempting to use resides at <tt>$ENV{'HTTP_REFERER'}</tt>, which is not allowed to access this cgi script.<p>
     </font></center>
    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
        }
        else {
            print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
 </body>
</html>
(END ERROR HTML)
        }
    }

    elsif ($error eq 'request_method') {
            print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Error: Request Method</title>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>Error: Request Method</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>The Request Method of the Form you submitted did not match
     either <tt>GET</tt> or <tt>POST</tt>.  Please check the form and make sure the
     <tt>method=</tt> statement is in upper case and matches <tt>GET</tt> or <tt>POST</tt>.<p>
    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
    }

    elsif ($error eq 'no_recipient') {
            print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Error: Bad/No Recipient</title>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>Error: Bad/No Recipient</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>There was no recipient or an invalid recipient specified in the data sent to FormMail. Please
     make sure you have filled in the <tt>recipient</tt> form field with an e-mail
     address that has been configured in <tt>\@recipients</tt>.
    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
    }

    elsif ($error eq 'missing_fields') {
        if ($Config{'missing_fields_redirect'}) {
            print "Location: $Config{'missing_fields_redirect'}\n\n";
        }
        else {
            foreach $missing_field (@error_fields) {
                $missing_field_list .= "      <li>$missing_field\n";
            }

            print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Error: Blank Fields</title>
 </head>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>Error: Blank Fields</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>The following fields were left blank in your submission form:<p>
     <ul>
$missing_field_list
     </ul><br>

     These fields must be filled in before you can successfully submit the form.<p>
     Please use your browser's back button to return to the form and try again.<hr size=1>
    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
        }
    }

    exit;
}


